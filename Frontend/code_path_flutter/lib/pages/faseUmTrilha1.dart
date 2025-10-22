// Arquivo: faseUmTrilha1.dart (SUBSTITUA O SEU ARQUIVO POR ESTE)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'trilhaUm.dart'; // Importa a tela do mapa

// Variáveis de estado do Quiz
const int QUIZ_SIZE = 3;

// 🚀 --- INÍCIO DA MODIFICAÇÃO (ExplicacaoModal) --- 🚀
class ExplicacaoModal extends StatelessWidget {
  final bool acertou;
  final String explicacao;
  final int faseId;
  final VoidCallback onClose;
  final bool isLastQuestion;
  final List<Color> gradientColors;
  final String animalAsset; // Adicionado: asset da imagem do animal

  const ExplicacaoModal({
    super.key,
    required this.acertou,
    required this.explicacao,
    required this.faseId,
    required this.onClose,
    this.isLastQuestion = false,
    required this.gradientColors,
    required this.animalAsset, // Adicionado ao construtor
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = acertou
        ? Colors.green.shade700
        : Colors.red.shade700;
    final Color lightBackground = acertou
        ? Colors.green.shade100
        : Colors.red.shade100;

    final String title = acertou
        ? (isLastQuestion ? "Fase Concluída! " : "Resposta Correta! ")
        : "Ops! Resposta Incorreta";

    // Agora o imageAsset é o animalAsset passado
    final String imageAssetToDisplay = animalAsset;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: lightBackground,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20),
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imageAssetToDisplay, height: 70), // Usa o animalAsset
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor, width: 2),
              ),
              child: Text(
                explicacao,
                textAlign: TextAlign.justify,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                acertou
                    ? (isLastQuestion ? "AVANÇAR FASE" : "PRÓXIMA PERGUNTA")
                    : "CONTINUAR (NOVA PERGUNTA)",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// --- Fim do Widget ExplicacaoModal ---
// 🚀 --- FIM DA MODIFICAÇÃO (ExplicacaoModal) --- 🚀

class QuestaoPage extends StatefulWidget {
  final int faseId;
  final String tipoModulo; // Este é o nome da API
  final String backgroundAsset;
  final List<Offset> posicoes;
  final String animalAsset;
  final List<Color> gradientColors;
  final String tipoModuloDisplay; // Nome de exibição

  const QuestaoPage({
    super.key,
    required this.faseId,
    required this.tipoModulo,
    required this.backgroundAsset,
    required this.posicoes,
    required this.animalAsset,
    required this.gradientColors,
    required this.tipoModuloDisplay,
  });

  @override
  State<QuestaoPage> createState() => _QuestaoPageState();
}

class _QuestaoPageState extends State<QuestaoPage> {
  List<Map<String, dynamic>> quizQuestions = [];
  int currentQuestionIndex = 0;
  int correctAnswers = 0;

  String enunciado = "";
  List<String> alternativas = [];
  String idPergunta = "";

  bool carregando = true;
  int? alternativaSelecionada;
  bool respostaEnviada = false;

  @override
  void initState() {
    super.initState();
    carregarNovoQuiz();
  }

  // --- Funções de carregar e salvar (SEM MUDANÇAS) ---

  Future<void> carregarNovoQuiz() async {
    return _fetchQuestions(QUIZ_SIZE);
  }

  Future<void> _replaceCurrentQuestion() async {
    await _fetchQuestions(1, isReplacement: true);
  }

  Future<void> _fetchQuestions(int count, {bool isReplacement = false}) async {
    try {
      setState(() {
        carregando = true;
        alternativaSelecionada = null;
        respostaEnviada = false;
        if (!isReplacement) {
          currentQuestionIndex = 0;
          correctAnswers = 0;
        }
      });

      final prefs = await SharedPreferences.getInstance();
      final nivel = prefs.getString("userNivel") ?? "iniciante";

      final mapaNiveis = {
        "iniciante": "Facil",
        "intermediario": "Medio",
        "avancado": "Dificil",
      };
      final nivelFirebase = mapaNiveis[nivel.toLowerCase()] ?? "Facil";

      final response = await http.get(
        Uri.parse(
          "http://127.0.0.1:8000/pergunta/?nivel=$nivelFirebase&tipo=${Uri.encodeComponent(widget.tipoModulo)}&count=$count",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> novasPerguntas = data["perguntas"] ?? [];

        if (novasPerguntas.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Não foi possível carregar mais perguntas."),
            ),
          );
          carregando = false;
          return;
        }

        setState(() {
          if (isReplacement) {
            quizQuestions[currentQuestionIndex] = Map<String, dynamic>.from(
              novasPerguntas.first,
            );
          } else {
            quizQuestions = novasPerguntas
                .map((p) => Map<String, dynamic>.from(p))
                .toList();
          }
          _loadCurrentQuestion();
          carregando = false;
        });
      } else {
        debugPrint("Erro ao buscar perguntas: ${response.statusCode}");
        carregando = false;
      }
    } catch (e) {
      debugPrint("Erro: $e");
      carregando = false;
    }
  }

  void _loadCurrentQuestion() {
    if (quizQuestions.isEmpty || currentQuestionIndex >= quizQuestions.length)
      return;

    final pergunta = quizQuestions[currentQuestionIndex];

    setState(() {
      enunciado = pergunta["pergunta"];
      alternativas = List<String>.from(pergunta["opcoes"]);
      idPergunta = pergunta["idPergunta"];
      alternativaSelecionada = null;
      respostaEnviada = false;
    });
  }

  Future<void> salvarProgressoENavegar() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail");
    if (email == null) return;

    final profileResp = await http.get(
      Uri.parse("http://127.0.0.1:8000/profile/$email"),
    );
    final profileData = jsonDecode(profileResp.body);
    final user = profileData["user"] ?? profileData;

    Map<String, dynamic> fasesMap = Map<String, dynamic>.from(
      user["fases"] ?? {},
    );
    List<Map<String, dynamic>> moduleFases = [];
    if (fasesMap.containsKey(widget.tipoModulo)) {
      moduleFases = List<Map<String, dynamic>>.from(
        fasesMap[widget.tipoModulo],
      );
    } else {
      moduleFases = List.generate(
        QUIZ_SIZE,
        (i) => {"id": i + 1, "liberada": i == 0, "atual": i == 0},
      );
    }

    int faseCompletadaId = widget.faseId;
    int proximaFaseId = faseCompletadaId + 1;

    bool trilhaCompletada = proximaFaseId > moduleFases.length;

    for (var fase in moduleFases) {
      fase["atual"] = false;

      if (fase["id"] == faseCompletadaId) {
        fase["liberada"] = true;
      }

      if (fase["id"] == proximaFaseId) {
        fase["atual"] = true;
        fase["liberada"] = true;
      }
    }

    if (trilhaCompletada) {
      if (moduleFases.isNotEmpty) {
        moduleFases.last["atual"] = true;
      }
    }

    fasesMap[widget.tipoModulo] = moduleFases;

    final payload = {
      "email": email,
      "tipo": widget.tipoModulo,
      "fases": moduleFases,
    };

    await http.post(
      Uri.parse("http://127.0.0.1:8000/salvar_progresso"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    final response = await http.get(
      Uri.parse("http://127.0.0.1:8000/profile/$email"),
    );
    final data = jsonDecode(response.body);
    final userNovo = data["user"];

    final Map<String, dynamic> fasesMapNovo = Map<String, dynamic>.from(
      userNovo["fases"] ?? {},
    );
    final List fasesAtualizadas = List<Map<String, dynamic>>.from(
      fasesMapNovo[widget.tipoModulo] ?? [],
    );

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TrilhaUm(
          tipoModulo: widget.tipoModuloDisplay,
          tipoModuloAPI: widget.tipoModulo,
          fases: fasesAtualizadas,
          backgroundAsset: widget.backgroundAsset,
          posicoes: widget.posicoes,
          animalAsset: widget.animalAsset,
          gradientColors: widget.gradientColors,
        ),
      ),
      (route) => false,
    );
  }

  void validarResposta() async {
    if (alternativaSelecionada == null || respostaEnviada) return;

    setState(() => respostaEnviada = true);

    final String respostaSelecionada = alternativas[alternativaSelecionada!];

    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/responder"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idPergunta": idPergunta,
        "resposta": respostaSelecionada,
      }),
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao validar resposta. Tente novamente."),
        ),
      );
      setState(() => respostaEnviada = false);
      return;
    }

    final data = jsonDecode(response.body);
    final bool correta = data["success"] ?? false;
    final String explicacao =
        data["explicacao"] ?? "A explicação não foi retornada.";

    final bool isLast = currentQuestionIndex == quizQuestions.length - 1;

    // 🚀 --- INÍCIO DA MODIFICAÇÃO (validarResposta) --- 🚀
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ExplicacaoModal(
          acertou: correta,
          explicacao: explicacao,
          faseId: widget.faseId,
          isLastQuestion: isLast,
          onClose: () {
            Navigator.pop(dialogContext);
          },
          gradientColors: widget.gradientColors,
          animalAsset: widget.animalAsset, // Passa o animalAsset aqui
        );
      },
    );
    // 🚀 --- FIM DA MODIFICAÇÃO (validarResposta) --- 🚀

    if (correta && isLast) {
      salvarProgressoENavegar();
    } else if (correta && !isLast) {
      setState(() {
        currentQuestionIndex++;
        _loadCurrentQuestion();
      });
    } else {
      _replaceCurrentQuestion();
    }
  }

  // --- Fim das Funções de carregar e salvar ---

  @override
  Widget build(BuildContext context) {
    if (carregando || quizQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String progressText =
        "Pergunta ${currentQuestionIndex + 1} de ${quizQuestions.length}";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Cabeçalho FIXO
              _buildCustomHeader(context),

              // Barra de progresso
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / quizQuestions.length,
                      backgroundColor: Colors.white54,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progressText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(179, 68, 38, 38),
                      ),
                    ),
                  ],
                ),
              ),

              // Área de quiz ROLÁVEL (agora em um Expanded)
              _buildQuizBody(),

              // Botão ENVIAR (agora FIXO no fundo)
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para o cabeçalho (Sem o animal)
  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
      child: Column(
        children: [
          // Botões de Voltar e Config
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              // Título (visível o tempo todo)
              Text(
                widget.tipoModuloDisplay.replaceAll("\n", " "),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  debugPrint("Configurações clicadas!");
                },
              ),
            ],
          ),

          // ❌ Animal Removido Daqui ❌

          // ❌ SizedBox Removido Daqui ❌
        ],
      ),
    );
  }

  // Widget para o corpo do quiz (rolável)
  Widget _buildQuizBody() {
    return Expanded(
      // Faz esta parte ocupar todo o espaço restante
      child: SingleChildScrollView(
        // Adiciona rolagem se o conteúdo for grande
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              // Card da pergunta
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      enunciado,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Alternativas
              ...alternativas.asMap().entries.map((entry) {
                final index = entry.key;
                final texto = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alternativaSelecionada == index
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white.withOpacity(0.7),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: alternativaSelecionada == index
                            ? const BorderSide(color: Colors.white, width: 2)
                            : BorderSide.none,
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),
                      elevation: 4,
                    ),
                    onPressed: respostaEnviada
                        ? null
                        : () {
                            setState(() => alternativaSelecionada = index);
                          },
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(
                height: 20,
              ), // Adiciona um espaço no final da rolagem
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET: Botão Enviar Fixo (Sem mudanças)
  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ElevatedButton(
        onPressed: alternativaSelecionada == null || respostaEnviada
            ? null
            : validarResposta,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black.withOpacity(0.4),
          elevation: 6,
        ),
        child: Text(
          respostaEnviada ? "PROCESSANDO..." : "Enviar",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: widget.gradientColors.first,
          ),
        ),
      ),
    );
  }
}
