import 'package:flutter/material.dart';
import 'faseUmTrilha1.dart'; // tela da fase 1 (exercício)

class TrilhaUm extends StatelessWidget {
  final List fases;

  const TrilhaUm({super.key, required this.fases});

  @override
  Widget build(BuildContext context) {
    // Posições das fases (você já ajustou isso)
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
                  "assets/imagens/fundo.png",
                  fit: BoxFit.cover,
                ),
              ),
              ...fases.asMap().entries.map((entry) {
                final i = entry.key;
                final fase = entry.value;
                final pos = posicoes[i];

                Widget icone;
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
                } else if (fase["liberada"] == true) {
                  icone = GestureDetector(
                    onTap: () {
                      if (fase["liberada"] == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuestaoPage(faseId: fase["id"]),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🔒 Fase bloqueada!")),
                        );
                      }
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
                } else {
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

                // posicionamento proporcional
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
