import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'trilhaUm.dart';
//import 'perfil.dart'; // ← página de perfil (caso ainda não exista, crie depois)
import 'login.dart';

class PaginaHome extends StatefulWidget {
  const PaginaHome({super.key});

  @override
  State<PaginaHome> createState() => _PaginaHomeState();
}

class _PaginaHomeState extends State<PaginaHome> {
  List<String> modulos = [];
  bool carregando = true;
  int _selectedIndex = 0;
  int streak = 0;
  String nomeUsuario = "Usuário";

  @override
  void initState() {
    super.initState();
    carregarModulos();
    carregarUsuario();
  }

  Future<void> carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email") ?? "";

    if (email.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["user"] != null) {
          setState(() {
            streak = data["user"]["streak"] ?? 0;
            nomeUsuario = data["user"]["nome"] ?? "Usuário";
          });
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
    }
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
      }
    } catch (e) {
      debugPrint("Erro ao carregar módulos: $e");
    }
  }

  void _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      // já está na Home
    } else if (index == 1) {
      // CONTINUAR TRILHA
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("email") ?? "";

      if (email.isEmpty) return;

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fases = data["user"]["fases"] as List?;
        final faseAtual = fases?.firstWhere(
          (f) => f["atual"] == true,
          orElse: () => null,
        );

        if (faseAtual != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TrilhaUm(tipoModulo: "Python do Zero 🐍"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nenhuma fase encontrada no perfil."),
              backgroundColor: Colors.black54,
            ),
          );
        }
      }
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 CABEÇALHO SUPERIOR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Olá, $nomeUsuario 👋",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$streak streak",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black87),
                    onPressed: () {
                      // TODO: abrir tela de configurações
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔹 CORPO PRINCIPAL
              const Text(
                "Trilhas disponíveis",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: carregando
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrilhaUm(tipoModulo: modulo),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade300,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
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
                                    color: Colors.white,
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
      ),

      // 🔹 BARRA INFERIOR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2C2C54),
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
