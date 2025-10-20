import 'package:flutter/material.dart';
import 'faseUmTrilha1.dart'; // tela da fase (QuestaoPage)

class TrilhaUm extends StatelessWidget {
  final String tipoModulo;
  final List fases;

  const TrilhaUm({super.key, required this.tipoModulo, required this.fases});

  // 🚀 Função auxiliar para determinar o ícone e a cor
  Widget _faseCirculo(bool liberada, {bool isCurrent = false}) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: liberada ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26, width: 2),
      ),
      child: Icon(
        // Se for a fase atual, é uma estrela (clicável, mas é onde ele está)
        // Se estiver liberada E não for a atual, é uma estrela (já concluída)
        // Se não estiver liberada (liberada=false), é um cadeado
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

  @override
  Widget build(BuildContext context) {
    final posicoes = [
      const Offset(0.24, 0.165),
      const Offset(0.60, 0.29),
      const Offset(0.42, 0.47),
      const Offset(0.60, 0.64),
      const Offset(0.45, 0.82),
    ];
    
    // 🔍 LÓGICA DE DETECÇÃO: Encontra o índice do nó "atual"
    final int currentNodex = fases.indexWhere((f) => f["atual"] == true);

    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1), 
      appBar: AppBar( 
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text( 
          tipoModulo,
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
                
                // 🚀 DETERMINAÇÃO DO ESTADO DA FASE
                final bool isCurrent = i == currentNodex;
                final bool estaLiberada = fase["liberada"] == true;
                
                // Ícone base: Estrela se liberada, Cadeado se bloqueada
                Widget icone = _faseCirculo(estaLiberada, isCurrent: isCurrent);

                // 1. 💥 SÓ ADICIONA O GATINHO SE FOR O NÓ ATUAL (CORREÇÃO DE FLUXO)
                if (isCurrent) {
                  icone = Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      icone, // Círculo da fase
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

                // 2. Torna Clicável se estiver liberada (inclui a fase atual)
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
                
                // 3. Posiciona o nó na tela
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
