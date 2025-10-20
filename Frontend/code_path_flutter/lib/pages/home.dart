import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'trilhaUm.dart';
import 'perfil.dart';
import 'tela_configuracao.dart';

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

  // 🚀 MAPA DE TRADUÇÃO: Colocado no topo da classe para garantir o escopo
  Map<String, String> get _moduloNameMap {
    return {
      
      "Laços de Repetição": "Laços de Repetição", 
      "Funções": "Funções",
      "Variáveis e Tipos de Dados": "Variáveis e Tipos de Dados", 
      "Condicionais": "Condicionais",
      "Perguntas diversas": "Perguntas diversas", 
    };
  }


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

  Future<void> carregarUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");

      if (email == null || email.isEmpty) return;

      // Código de mapeamento removido daqui
      
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

  Future<void> abrirTrilha(String tipoModulo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null) return;

      // 1. 🚀 TRADUÇÃO: Usa o mapa para encontrar o nome do API/Firestore
      final String nomeModuloAPI = _moduloNameMap[tipoModulo] ?? tipoModulo; // 💥 Esta linha agora funciona

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"] ?? data;
        final fasesData = user["fases"];
        
        // 2. Extrai as fases usando o NOME DA API
        final Map<String, dynamic> fasesMap = Map<String, dynamic>.from(fasesData ?? {});
        List<Map<String, dynamic>> fases = List<Map<String, dynamic>>.from(fasesMap[nomeModuloAPI] ?? []);

        // 🚀 CORREÇÃO PRINCIPAL: Se a lista de fases para o módulo estiver vazia, INICIALIZA
        if (fases.isEmpty) {
             fases = List.generate(
                5, // Número padrão de fases
                (i) => {
                  "id": i + 1,
                  "liberada": i == 0 ? true : false, // A primeira fase (id=1) é liberada
                  "atual": i == 0 ? true : false, // O usuário começa na primeira
                },
            );
            
            // Opcional: Chama o salvar_progresso para persistir esta inicialização
            final payload = {"email": email, "tipo": nomeModuloAPI, "fases": fases};
            await http.post(
              Uri.parse("http://10.0.2.2:8000/salvar_progresso"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(payload),
            );
        }
        
        // 3. Envia o NOME DA API e a lista de fases (agora garantida) para a TrilhaUm
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrilhaUm(tipoModulo: nomeModuloAPI, fases: fases),
          ),
        );

        carregarUsuario();
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
        // Usa o nome do primeiro módulo para abrir a trilha
        abrirTrilha(modulos.first);
      }
    } else if (index == 2) {
      if (email != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerfilPage()),
        );
        carregarUsuario();
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConfiguracoesPage(),
                      ),
                    );
                    carregarUsuario();
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
