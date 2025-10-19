import 'package:flutter/material.dart';
import 'faseUmTrilha1.dart'; // tela da fase (QuestaoPage)

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
      backgroundColor: const Color(0xFFDFF5E1), // Adicione uma cor de fundo se quiser
      appBar: AppBar( // 🚀 NOVO: Adiciona o AppBar
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Volta para a tela anterior (PaginaHome)
          },
        ),
        title: Text( // Opcional: Título da Trilha
          tipoModulo, // Mostra o nome do módulo atual
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              ...fases.asMap().entries.map((entry) {
                final i = entry.key;
                final fase = entry.value;
                final pos = posicoes[i % posicoes.length];

                final bool estaLiberada = fase["liberada"] == true || fase["atual"] == true;
                Widget icone = _faseCirculo(estaLiberada);

                if (fase["atual"] == true) {
                  icone = Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      icone,
                      Positioned(
                        top: -80,
                        child: Column(
                          children: [
                            Image.asset("assets/imagens/gato1.png", height: 60),
                            const SizedBox(height: 6),
                            _tag("Você está aqui"),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                if (estaLiberada) {
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
                    child: icone,
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

  Widget _faseCirculo(bool liberada) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: liberada ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26, width: 2),
      ),
      child: Icon(
        liberada ? Icons.star : Icons.lock,
        color: liberada ? Colors.yellow : Colors.white,
        size: 35,
      ),
    );
  }

  Widget _tag(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}