import 'package:flutter/material.dart';
import 'faseUmTrilha1.dart'; // tela da fase (QuestaoPage)

class TrilhaUm extends StatelessWidget {
  final String tipoModulo;
  final List fases;
  final String backgroundAsset;
  final List<Offset> posicoes;
  final String tipoModuloAPI;
  final String animalAsset;
  final List<Color> gradientColors;

  const TrilhaUm({
    super.key,
    required this.tipoModulo,
    required this.fases,
    required this.backgroundAsset,
    required this.posicoes,
    required this.animalAsset,
    required this.gradientColors,
    required this.tipoModuloAPI,
  });

  // A função _tag (para o gato) continua igual
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
    final int currentNodex = fases.indexWhere((f) => f["atual"] == true);

    return Scaffold(
      // 1. 🚀 CORREÇÃO: REMOVEMOS o 'extendBodyBehindAppBar: true'

      // 2. 🚀 CORREÇÃO: Este é o AppBar novo e correto
      appBar: AppBar(
        // Botão de voltar branco
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        // Título com a imagem do animal
        title: Row(
          children: [
            Image.asset(
              animalAsset, // Usa a foto do animal
              height: 40,
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Text(
                tipoModulo,
                style: const TextStyle(
                  color: Colors.white, // Texto branco
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // O degradê (flexibleSpace) vai AQUI DENTRO
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors, // Usa as cores do módulo
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),

      // O 'flexibleSpace' que estava aqui fora foi removido.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // IMAGEM DE FUNDO (Continua igual)
              Positioned.fill(
                child: Image.asset(backgroundAsset, fit: BoxFit.cover),
              ),

              // LÓGICA DE ÍCONES (Continua igual)
              ...fases.asMap().entries.map((entry) {
                final i = entry.key;
                final fase = entry.value;
                final pos = posicoes[i % posicoes.length];

                final bool isCurrent = i == currentNodex;
                final bool estaLiberada = fase["liberada"] == true;

                Widget iconeCentral;
                Widget? tag;

                if (isCurrent) {
                  iconeCentral = Image.asset(
                    "assets/imagens/gato1.png",
                    height: 60,
                  );
                  tag = Positioned(top: -30, child: _tag("Você está aqui"));
                } else if (estaLiberada) {
                  iconeCentral = const Icon(
                    Icons.star,
                    color: Color(0xFFFBC02D),
                    size: 45,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4.0)],
                  );
                  tag = null;
                } else {
                  iconeCentral = const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 35,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4.0)],
                  );
                  tag = null;
                }

                // Posiciona o grupo (Ícone + Tag) na tela
                return Positioned(
                  left: constraints.maxWidth * pos.dx - 35,
                  top: constraints.maxHeight * pos.dy - 35,

                  child: GestureDetector(
                    onTap: estaLiberada
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuestaoPage(
                                  faseId: fase["id"],
                                  tipoModulo: tipoModuloAPI,
                                  tipoModuloDisplay: tipoModulo,
                                  backgroundAsset: backgroundAsset,
                                  posicoes: posicoes,

                                  // 3. 🚀 CORREÇÃO: Passando os novos dados
                                  animalAsset: animalAsset,
                                  gradientColors: gradientColors,
                                ),
                              ),
                            );
                          }
                        : null,

                    // O "alvo" clicável (Continua igual)
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          color: Colors.transparent,
                        ),
                        iconeCentral,
                        if (tag != null) tag,
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
