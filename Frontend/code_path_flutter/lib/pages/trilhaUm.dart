import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'faseUmTrilha1.dart';

class TrilhaUm extends StatefulWidget {
  final String tipoModulo;
  final List<dynamic> fases;

  const TrilhaUm({super.key, required this.tipoModulo, this.fases = const []});

  @override
  State<TrilhaUm> createState() => _TrilhaUmState();
}

class _TrilhaUmState extends State<TrilhaUm> {
  List<dynamic> fases = [];
  bool carregando = true;
  int faseAtual = 1;

  @override
  void initState() {
    super.initState();
    carregarProgresso();
  }

  Future<void> carregarProgresso() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null) return;

      // Busca o perfil do usuário com as fases
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"];
        final listaFases = List<Map<String, dynamic>>.from(user["fases"]);

        setState(() {
          fases = listaFases;
          faseAtual = listaFases.firstWhere(
            (f) => f["atual"] == true,
            orElse: () => listaFases.first,
          )["id"];
          carregando = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar progresso: $e");
    }
  }

  void abrirFase(int faseId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuestaoPage(faseId: faseId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final posicoes = [
                  const Offset(0.24, 0.165),
                  const Offset(0.64, 0.377),
                  const Offset(0.393, 0.577),
                  const Offset(0.58, 0.73),
                  const Offset(0.435, 0.87),
                ];

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        "assets/imagens/fundo1.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                    ...fases.asMap().entries.map((entry) {
                      final i = entry.key;
                      final fase = entry.value;
                      final pos = posicoes[i % posicoes.length];

                      Widget icone;

                      if (fase["atual"] == true) {
                        icone = Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            _buildFaseAtiva(),
                            Positioned(
                              top: -80,
                              child: Column(
                                children: [
                                  Image.asset(
                                    "assets/imagens/gato1.png",
                                    height: 60,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade800,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Você está aqui",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else if (fase["liberada"] == true) {
                        icone = GestureDetector(
                          onTap: () => abrirFase(fase["id"]),
                          child: _buildFaseLiberada(),
                        );
                      } else {
                        icone = _buildFaseBloqueada();
                      }

                      return Positioned(
                        left: constraints.maxWidth * pos.dx - 35,
                        top: constraints.maxHeight * pos.dy - 35,
                        child: icone,
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildFaseAtiva() => Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      color: Colors.green,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black26, width: 2),
    ),
    child: const Icon(Icons.star, color: Colors.yellow, size: 35),
  );

  Widget _buildFaseLiberada() => Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      color: Colors.green,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black26, width: 2),
    ),
    child: const Icon(Icons.star_border, color: Colors.yellow, size: 35),
  );

  Widget _buildFaseBloqueada() => Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      color: Colors.grey,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black26, width: 2),
    ),
    child: const Icon(Icons.lock, color: Colors.white, size: 35),
  );
}
