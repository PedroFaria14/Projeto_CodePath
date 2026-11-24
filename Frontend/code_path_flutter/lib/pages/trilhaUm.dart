import 'package:flutter/material.dart';
import 'faseUmTrilha1.dart'; // tela da fase (QuestaoPage)

class TrilhaUm extends StatefulWidget {
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

  @override
  State<TrilhaUm> createState() => _TrilhaUmState();
}

class _TrilhaUmState extends State<TrilhaUm> {
  late List _fasesAtuais;
  late int _indiceAtual;

  @override
  void initState() {
    super.initState();
    print("TrilhaUm initState"); // Log
    _atualizarFases(widget.fases);
  }

  void _atualizarFases(List novasFases) {
    if (!mounted) {
      print(
        "TrilhaUm: Tentativa de atualizar estado, mas widget não está montado.",
      ); // Log
      return;
    }
    setState(() {
      _fasesAtuais = List<Map<String, dynamic>>.from(
        novasFases.map((f) {
          if (f is Map) {
            return Map<String, dynamic>.from(f);
          } else {
            print("TrilhaUm: Item inesperado na lista de fases recebida: $f");
            return <String, dynamic>{};
          }
        }),
      );
      _indiceAtual = _fasesAtuais.indexWhere(
        (f) => f.containsKey("atual") && f["atual"] == true,
      );
      print("TrilhaUm State Updated: Novas fases: $_fasesAtuais"); // Log
      print("TrilhaUm State Updated: Novo índice atual: $_indiceAtual"); // Log
    });
  }

  Widget _tag(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _navegarParaQuestao(Map<String, dynamic> fase) async {
    print(
      "TrilhaUm: Navegando para QuestaoPage para fase ID: ${fase['id']}",
    ); // Log
    if (!mounted) {
      print(
        "TrilhaUm: Tentativa de navegar, mas widget não está montado.",
      ); // Log
      return;
    }
    final resultado = await Navigator.push<List<dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestaoPage(
          faseId: fase["id"],
          tipoModulo: widget.tipoModuloAPI,
          tipoModuloDisplay: widget.tipoModulo,
          backgroundAsset: widget.backgroundAsset,
          posicoes: widget.posicoes,
          animalAsset: widget.animalAsset,
          gradientColors: widget.gradientColors,
        ),
      ),
    );

    print("TrilhaUm: Retornou da QuestaoPage. Resultado: $resultado"); // Log

    if (resultado != null && mounted) {
      print(
        "TrilhaUm: QuestaoPage retornou fases atualizadas. Atualizando estado.",
      ); // Log
      _atualizarFases(resultado);
    } else if (mounted) {
      print(
        "TrilhaUm: QuestaoPage retornou nulo ou tipo inesperado (${resultado?.runtimeType}). Estado não atualizado.",
      ); // Log
    } else {
      print(
        "TrilhaUm: Retornou da QuestaoPage, mas widget não está mais montado.",
      ); // Log
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      "TrilhaUm build: Índice atual: $_indiceAtual, Contagem de fases: ${_fasesAtuais.length}",
    ); // Log

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print(
              "TrilhaUm: Botão voltar pressionado. Voltando para PaginaHome.",
            ); // Log
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Image.asset(widget.animalAsset, height: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.tipoModulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 2,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_fasesAtuais.isEmpty || widget.posicoes.isEmpty) {
            print("TrilhaUm build: Lista de fases ou posições vazia."); // Log
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(widget.backgroundAsset, fit: BoxFit.cover),
                ),
                const Center(
                  child: Card(
                    color: Colors.black54,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "Nenhuma fase encontrada para este módulo.",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(widget.backgroundAsset, fit: BoxFit.cover),
              ),

              ..._fasesAtuais.asMap().entries.map((entry) {
                final i = entry.key;
                final fase = entry.value;
                final posIndex = i % widget.posicoes.length;
                final pos = widget.posicoes[posIndex];

                final bool isCurrent = i == _indiceAtual;
                final bool estaLiberada = fase["liberada"] == true;

                Widget iconeCentral;
                Widget? tagWidget;

                if (isCurrent && estaLiberada) {
                  iconeCentral = Image.asset(
                    "assets/imagens/gato1.png",
                    height: 60,
                  );
                  tagWidget = Positioned(
                    top: -25,
                    left: -30,
                    right: -30,
                    child: Center(child: _tag("Você está aqui")),
                  );
                } else if (estaLiberada) {
                  iconeCentral = const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFBC02D),
                    size: 45,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4.0)],
                  );
                } else {
                  iconeCentral = const Icon(
                    Icons.lock_rounded,
                    color: Colors.white70,
                    size: 35,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4.0)],
                  );
                }

                final double clickableSize = 70.0;
                final leftPos =
                    constraints.maxWidth * pos.dx - (clickableSize / 2);
                final topPos =
                    constraints.maxHeight * pos.dy - (clickableSize / 2);
                final safeLeft = leftPos.clamp(
                  5.0,
                  constraints.maxWidth - clickableSize - 5.0,
                );
                final safeTop = topPos.clamp(
                  5.0,
                  constraints.maxHeight - clickableSize - 5.0,
                );

                return Positioned(
                  left: safeLeft,
                  top: safeTop,
                  child: GestureDetector(
                    onTap: estaLiberada
                        ? () => _navegarParaQuestao(fase)
                        : null,
                    child: MouseRegion(
                      cursor: estaLiberada
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: Container(
                        width: clickableSize,
                        height: clickableSize,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // 🚀 REMOVIDA AQUI: A secção que criava a "bola branca" / efeito de brilho
                            // if(estaLiberada) Container(...) foi removida.
                            iconeCentral,
                            if (tagWidget != null) tagWidget,
                          ],
                        ),
                      ),
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

  @override
  void dispose() {
    print("TrilhaUm dispose"); // Log
    super.dispose();
  }
}
