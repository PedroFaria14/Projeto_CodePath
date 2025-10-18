import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'trilhaUm.dart';
import 'perfil.dart';

class PaginaHome extends StatefulWidget {
  const PaginaHome({super.key});

  @override
  State<PaginaHome> createState() => _PaginaHomeState();
}

class _PaginaHomeState extends State<PaginaHome> {
  List<String> modulos = [];
  bool carregando = true;
  int streak = 0;
  String nomeUsuario = "Usuário";
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    carregarModulos();
    carregarUsuario();
  }

  Future<void> carregarModulos() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/modulos"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          modulos = List<String>.from(data["modulos"]);
          carregando = false;
        });
      } else {
        debugPrint("Erro ao buscar módulos: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro ao carregar módulos: $e");
    }
  }

  /// 🔹 Busca nome e streak do usuário
  Future<void> carregarUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null || email.isEmpty) return;

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          streak = data["user"]["streak"] ?? 0;
          nomeUsuario = data["user"]["nome"] ?? "Usuário";
        });
      } else {
        debugPrint("Erro ao carregar perfil: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
    }
  }

  /// 🔹 Abre trilha com as fases do módulo selecionado
  Future<void> abrirTrilha(String tipoModulo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null) return;

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"] ?? data;
        final fasesData = user["fases"];
        List<Map<String, dynamic>> fases = [];

        // 🔹 Compatível com versões antigas e novas
        if (fasesData is List) {
          fases = List<Map<String, dynamic>>.from(fasesData);
        } else if (fasesData is Map && fasesData.containsKey(tipoModulo)) {
          fases = List<Map<String, dynamic>>.from(fasesData[tipoModulo]);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrilhaUm(tipoModulo: tipoModulo, fases: fases),
          ),
        );
      } else {
        debugPrint("Erro ao carregar fases do usuário: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao abrir trilha: $e");
    }
  }

  void _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail");

    if (index == 0) {
      // já está na home
    } else if (index == 1) {
      if (modulos.isNotEmpty) {
        abrirTrilha(modulos.first);
      }
    } else if (index == 2) {
      if (email != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerfilPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Olá, $nomeUsuario 👋",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$streak",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PerfilPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trilhas disponíveis",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: modulos.length,
                      itemBuilder: (context, index) {
                        final modulo = modulos[index];
                        return GestureDetector(
                          onTap: () => abrirTrilha(modulo),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade200,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                modulo,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.black54,
        backgroundColor: const Color(0xFFE0F8E0),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow_rounded),
            label: "Continuar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
