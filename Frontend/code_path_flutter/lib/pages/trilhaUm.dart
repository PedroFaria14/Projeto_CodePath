import 'package:flutter/material.dart';
import 'faseUmTrilha1.dart';

class TrilhaUm extends StatelessWidget {
  final String tipoModulo;
  final List fases;

  const TrilhaUm({super.key, required this.tipoModulo, required this.fases});

  @override
  Widget build(BuildContext context) {
    final posicoes = [
      const Offset(0.24, 0.165),
      const Offset(0.60, 0.29),
      const Offset(0.42, 0.47),
      const Offset(0.60, 0.64),
      const Offset(0.45, 0.82),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
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

                // 🔹 Fase atual
                if (fase["atual"] == true) {
                  icone = Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26, width: 2),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 35,
                        ),
                      ),
                      Positioned(
                        top: -80,
                        child: Column(
                          children: [
                            Image.asset("assets/imagens/gato1.png", height: 60),
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
                }
                // 🔹 Fase liberada
                else if (fase["liberada"] == true) {
                  icone = GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuestaoPage(
                            faseId: fase["id"],
                            tipoModulo: tipoModulo,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.yellow,
                        size: 35,
                      ),
                    ),
                  );
                }
                // 🔹 Fase bloqueada
                else {
                  icone = Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 2),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 35,
                    ),
                  );
                }

                return Positioned(
                  left: constraints.maxWidth * pos.dx - 35,
                  top: constraints.maxHeight * pos.dy - 35,
                  child: icone,
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
