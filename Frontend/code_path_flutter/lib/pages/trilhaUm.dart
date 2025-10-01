import 'package:flutter/material.dart';
import 'faseUmTrilha1.dart';

class ModuloPage extends StatelessWidget {
  const ModuloPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fases = [
      {"id": 1, "liberada": true, "atual": false},
      {"id": 2, "liberada": true, "atual": true},
      {"id": 3, "liberada": false, "atual": false},
      {"id": 4, "liberada": false, "atual": false},
      {"id": 5, "liberada": false, "atual": false},
    ];

    final positions = [
      const Offset(0.24, 0.165),
      const Offset(0.64, 0.377),
      const Offset(0.393, 0.577),
      const Offset(0.58, 0.73),
      const Offset(0.435, 0.87),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text(
          "MÓDULO 1 - Exercícios de Repetição",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/imagens/gato1.png"),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),

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

              //posições
              ...fases.asMap().entries.map((entry) {
                final i = entry.key;
                final fase = entry.value;
                final pos = positions[i];

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              QuestaoPage(faseId: fase['id'] as int),
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

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: "Módulos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            label: "Recarregar",
          ),
        ],
      ),
    );
  }
}
