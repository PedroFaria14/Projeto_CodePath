// Arquivo: faseUmTrilha1.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// Remova a importação de 'trilhaUm.dart' daqui se ela não for usada diretamente
// import 'trilhaUm.dart';

// Variáveis de estado do Quiz
const int QUIZ_SIZE = 3; // Define o número de perguntas por fase

// --- Widget ExplicacaoModal (sem alterações) ---
class ExplicacaoModal extends StatelessWidget {
  final bool acertou;
  final String explicacao;
  final int faseId;
  final VoidCallback onClose;
  final bool isLastQuestion;
  final List<Color> gradientColors;
  final String animalAsset;

  const ExplicacaoModal({
    super.key,
    required this.acertou,
    required this.explicacao,
    required this.faseId,
    required this.onClose,
    this.isLastQuestion = false,
    required this.gradientColors,
    required this.animalAsset,
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
        ? (isLastQuestion ? "Fase Concluída!" : "Resposta Correta!")
        : "Ops! Resposta Incorreta";
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
            Image.asset(imageAssetToDisplay, height: 70),
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
                    ? (isLastQuestion ? "CONCLUIR FASE" : "PRÓXIMA PERGUNTA")
                    : "TENTE NOVAMENTE",
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

class QuestaoPage extends StatefulWidget {
  final int faseId;
  final String tipoModulo; // Nome da API
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
  // correctAnswers não era usado, pode ser removido se não precisar
  // int correctAnswers = 0;

  String enunciado = "";
  List<String> alternativas = [];
  String idPergunta = "";

  bool carregando = true;
  int? alternativaSelecionada;
  bool respostaEnviada = false;

  @override
  void initState() {
    super.initState();
    print("QuestaoPage initState for fase ${widget.faseId}"); // Log
    carregarNovoQuiz();
  }

  // --- Funções de carregar perguntas ---
  Future<void> carregarNovoQuiz() async {
    print("QuestaoPage: carregarNovoQuiz (fetch ${QUIZ_SIZE} questions)");
    return _fetchQuestions(QUIZ_SIZE);
  }

  Future<void> _replaceCurrentQuestion() async {
    print("QuestaoPage: _replaceCurrentQuestion (fetch 1 question)");
    await _fetchQuestions(1, isReplacement: true);
  }

  Future<void> _fetchQuestions(int count, {bool isReplacement = false}) async {
    if (!mounted) return; // Verifica no início

    // Mostra loading
    setState(() {
      carregando = true;
      alternativaSelecionada = null;
      respostaEnviada = false;
      // Não reseta index/correctAnswers se for substituição
      if (!isReplacement) {
        currentQuestionIndex = 0;
        // correctAnswers = 0;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final nivel = prefs.getString("userNivel") ?? "iniciante";
      final mapaNiveis = {
        "iniciante": "Facil",
        "intermediario": "Medio",
        "avancado": "Dificil",
      };
      final nivelFirebase = mapaNiveis[nivel.toLowerCase()] ?? "Facil";

      print(
        "QuestaoPage: Fetching $count question(s) - Nivel: $nivelFirebase, Tipo: ${widget.tipoModulo}",
      ); // Log

      final response = await http.get(
        Uri.parse(
          "https://projeto-codepath.onrender.com/pergunta/?nivel=$nivelFirebase&tipo=${Uri.encodeComponent(widget.tipoModulo)}&count=$count",
        ),
      );

      if (!mounted) return; // Verifica após chamada async

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> novasPerguntas = data["perguntas"] ?? [];

        if (novasPerguntas.isEmpty) {
          print("QuestaoPage: API did not return questions."); // Log
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Não há mais perguntas disponíveis para esta fase.",
              ),
            ),
          );
          // Considerar voltar para TrilhaUm aqui? Ou mostrar mensagem permanente?
          setState(() => carregando = false);
          // Navigator.pop(context); // Exemplo: Voltar se não houver perguntas
          return;
        }

        print(
          "QuestaoPage: Questions received: ${novasPerguntas.length}",
        ); // Log

        setState(() {
          if (isReplacement) {
            if (currentQuestionIndex < quizQuestions.length) {
              quizQuestions[currentQuestionIndex] = Map<String, dynamic>.from(
                novasPerguntas.first,
              );
              print(
                "QuestaoPage: Replaced question at index $currentQuestionIndex",
              ); // Log
            } else {
              print(
                "QuestaoPage: Error replacing question - index out of bounds.",
              ); // Log erro
            }
          } else {
            quizQuestions = novasPerguntas
                .map((p) => Map<String, dynamic>.from(p))
                .toList();
            print(
              "QuestaoPage: Loaded new quiz with ${quizQuestions.length} questions.",
            ); // Log
          }
          // Garante que o índice é válido antes de carregar
          if (currentQuestionIndex < quizQuestions.length) {
            _loadCurrentQuestion();
          } else {
            print(
              "QuestaoPage: Error loading current question - index out of bounds after fetch.",
            ); // Log erro
            // Lidar com erro? Voltar? Mostrar mensagem?
          }
          carregando = false; // Esconde loading AQUI
        });
      } else {
        print(
          "QuestaoPage: Error fetching questions - Status ${response.statusCode}",
        ); // Log
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ${response.statusCode} ao buscar perguntas."),
          ),
        );
        setState(() => carregando = false);
        // Considerar voltar para TrilhaUm em caso de erro?
        // Navigator.pop(context);
      }
    } catch (e, stacktrace) {
      print("QuestaoPage: Exception during fetchQuestions: $e"); // Log
      print(stacktrace); // Log stacktrace
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro de conexão ao buscar perguntas: $e")),
        );
        setState(() => carregando = false);
      }
    }
  }

  void _loadCurrentQuestion() {
    // Verifica se o índice é válido
    if (quizQuestions.isEmpty || currentQuestionIndex >= quizQuestions.length) {
      print(
        "QuestaoPage: Attempted to load question with invalid index $currentQuestionIndex or empty list.",
      ); // Log
      // O que fazer aqui? Talvez voltar?
      // Navigator.pop(context);
      return;
    }

    final pergunta = quizQuestions[currentQuestionIndex];
    print(
      "QuestaoPage: Loading question index $currentQuestionIndex, ID: ${pergunta['idPergunta']}",
    ); // Log

    setState(() {
      enunciado = pergunta["pergunta"] ?? "Erro: Enunciado não encontrado";
      // Garante que 'opcoes' é uma lista de strings
      alternativas = List<String>.from(pergunta["opcoes"] ?? []);
      idPergunta = pergunta["idPergunta"] ?? ""; // Garante que é string
      alternativaSelecionada = null;
      respostaEnviada = false;
    });
  }
  // --- Fim Funções de carregar ---

  // --- 🚀 FUNÇÃO salvarProgressoENavegar CORRIGIDA ---
  Future<void> salvarProgressoENavegar() async {
    print(
      "QuestaoPage: Iniciando salvarProgressoENavegar para fase ${widget.faseId}",
    ); // Log
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail");
    if (email == null) {
      print("QuestaoPage: Erro salvando progresso - email nulo."); // Log
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: Usuário não logado.")),
        );
      return;
    }

    List<Map<String, dynamic>> moduleFasesCalculadas = []; // Lista para retorno

    try {
      // --- Lógica para buscar perfil e calcular novas fases ---
      print("QuestaoPage: Buscando perfil atual para $email"); // Log
      final profileResp = await http.get(
        Uri.parse("https://projeto-codepath.onrender.com/profile/$email"),
      );

      if (!mounted) return;

      if (profileResp.statusCode != 200) {
        print(
          "QuestaoPage: Erro ${profileResp.statusCode} ao buscar perfil para salvar progresso.",
        ); // Log
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao buscar dados atuais.")),
        );
        // Tentar voltar mesmo assim? Ou travar? Por segurança, vamos apenas voltar.
        Navigator.pop(context); // Volta sem dados atualizados
        return;
      }

      final profileData = jsonDecode(profileResp.body);
      final user = profileData["user"] ?? profileData;
      final dynamic fasesData = user["fases"];
      Map<String, dynamic> fasesMap;

      if (fasesData is Map) {
        fasesMap = Map<String, dynamic>.from(fasesData);
      } else {
        fasesMap = {}; // Começa vazio se for lista ou nulo
      }

      List<Map<String, dynamic>> currentModuleFases = [];
      if (fasesMap.containsKey(widget.tipoModulo)) {
        currentModuleFases = List<Map<String, dynamic>>.from(
          fasesMap[widget.tipoModulo],
        );
      } else {
        // Inicializa se o módulo não existe (IMPORTANTE: Usar um número fixo de fases ou buscar do backend?)
        // Vamos assumir 5 fases por enquanto
        print(
          "QuestaoPage: Módulo ${widget.tipoModulo} não encontrado no perfil. Inicializando localmente.",
        ); // Log
        currentModuleFases = List.generate(
          5,
          (i) => {"id": i + 1, "liberada": i == 0, "atual": i == 0},
        );
      }

      // --- Cálculo do novo estado das fases ---
      int faseCompletadaId = widget.faseId;
      int proximaFaseId = faseCompletadaId + 1;
      int totalFasesModulo =
          currentModuleFases.length; // Usa o tamanho real da lista
      bool trilhaCompletada = proximaFaseId > totalFasesModulo;

      print(
        "QuestaoPage: Calculando novo estado. Fase completada: $faseCompletadaId, Próxima: $proximaFaseId, Total: $totalFasesModulo, Trilha Completa: $trilhaCompletada",
      ); // Log

      // Cria uma NOVA lista para não modificar a original diretamente no loop
      List<Map<String, dynamic>> novasFasesModulo = currentModuleFases.map((
        fase,
      ) {
        // Cria uma cópia do mapa da fase
        Map<String, dynamic> novaFase = Map<String, dynamic>.from(fase);
        novaFase["atual"] = false; // Desmarca todas como 'atual'

        if (novaFase["id"] == faseCompletadaId) {
          novaFase["liberada"] = true; // Garante que a completada está liberada
        }

        if (novaFase["id"] == proximaFaseId && !trilhaCompletada) {
          novaFase["atual"] = true; // Marca a próxima como atual
          novaFase["liberada"] = true; // Libera a próxima
        }
        return novaFase;
      }).toList();

      if (trilhaCompletada && novasFasesModulo.isNotEmpty) {
        // Se completou a trilha, marca a ÚLTIMA fase como 'atual' (ou outra lógica)
        print(
          "QuestaoPage: Trilha completada. Marcando última fase como atual.",
        ); // Log
        novasFasesModulo.last["atual"] = true;
      }
      // --- Fim do cálculo ---

      moduleFasesCalculadas = novasFasesModulo; // Guarda para o retorno

      // --- Salva o progresso no backend ---
      final payload = {
        "email": email,
        "tipo": widget.tipoModulo,
        "fases": moduleFasesCalculadas,
      };
      print(
        "QuestaoPage: Salvando progresso no backend. Payload: $payload",
      ); // Log

      final saveResp = await http.post(
        Uri.parse("https://projeto-codepath.onrender.com/salvar_progresso"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (saveResp.statusCode != 200) {
        print(
          "QuestaoPage: Erro ${saveResp.statusCode} ao salvar progresso.",
        ); // Log
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao salvar progresso.")),
        );
        // Continua para voltar mesmo com erro de salvamento
      } else {
        print("QuestaoPage: Progresso salvo com sucesso."); // Log
      }
      // --- Fim do salvamento ---
    } catch (e, stacktrace) {
      print("QuestaoPage: EXCEÇÃO GERAL em salvarProgressoENavegar: $e"); // Log
      print(stacktrace); // Log
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro inesperado ao salvar.")),
        );
      // Tenta voltar mesmo com exceção? Ou deixa o usuário preso? Vamos voltar.
      Navigator.pop(
        context,
        moduleFasesCalculadas.isNotEmpty ? moduleFasesCalculadas : null,
      ); // Tenta retornar o calculado localmente
      return; // Sai da função
    }

    // 🚀 CORREÇÃO PRINCIPAL: Voltar para a TrilhaUm existente
    if (mounted) {
      print(
        "QuestaoPage: Voltando para TrilhaUm com as fases atualizadas: $moduleFasesCalculadas",
      ); // Log
      // Apenas fecha a tela atual (QuestaoPage) e envia a lista de fases atualizada
      // de volta para a tela TrilhaUm que a chamou.
      Navigator.pop(context, moduleFasesCalculadas); // <--- MUDANÇA AQUI
    } else {
      print(
        "QuestaoPage: Widget desmontado antes do Navigator.pop final.",
      ); // Log
    }
  }
  // --- FIM DA FUNÇÃO salvarProgressoENavegar ---

  // --- Função validarResposta (Ajustada para clareza) ---
  void validarResposta() async {
    if (alternativaSelecionada == null || respostaEnviada) return;

    setState(() => respostaEnviada = true); // Bloqueia botões

    final String respostaSelecionada = alternativas[alternativaSelecionada!];
    print(
      "QuestaoPage: Validando resposta '${respostaSelecionada}' para pergunta ID $idPergunta",
    ); // Log

    bool correta = false;
    String explicacao = "Não foi possível validar a resposta.";

    try {
      final response = await http.post(
        Uri.parse("https://projeto-codepath.onrender.com/responder"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idPergunta": idPergunta,
          "resposta": respostaSelecionada,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        correta = data["success"] ?? false;
        explicacao = data["explicacao"] ?? "Explicação não disponível.";
        print("QuestaoPage: Resposta validada. Correta: $correta"); // Log
      } else {
        print(
          "QuestaoPage: Erro ${response.statusCode} ao validar resposta.",
        ); // Log
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao validar resposta.")),
        );
        setState(
          () => respostaEnviada = false,
        ); // Libera botões para tentar de novo
        return; // Não continua se a validação falhou
      }
    } catch (e) {
      print("QuestaoPage: Exceção ao validar resposta: $e"); // Log
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro de conexão ao validar.")),
        );
      if (mounted) setState(() => respostaEnviada = false); // Libera botões
      return; // Não continua
    }

    // --- Mostra o Modal ---
    final bool isLast = currentQuestionIndex == quizQuestions.length - 1;
    print(
      "QuestaoPage: Mostrando modal. Correta: $correta, Última: $isLast",
    ); // Log

    await showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora
      builder: (BuildContext dialogContext) {
        return ExplicacaoModal(
          acertou: correta,
          explicacao: explicacao,
          faseId: widget.faseId,
          isLastQuestion: isLast,
          onClose: () {
            print("QuestaoPage: Fechando modal."); // Log
            Navigator.pop(dialogContext); // Fecha SÓ o diálogo
          },
          gradientColors: widget.gradientColors,
          animalAsset: widget.animalAsset,
        );
      },
    ); // Espera o modal ser fechado

    if (!mounted) return; // Verifica DEPOIS que o modal fechou

    // --- Decide o próximo passo ---
    if (correta && isLast) {
      print(
        "QuestaoPage: Resposta correta e última pergunta. Chamando salvarProgressoENavegar.",
      ); // Log
      // Se acertou a última, salva e volta (usando a função corrigida)
      salvarProgressoENavegar();
    } else if (correta && !isLast) {
      print(
        "QuestaoPage: Resposta correta, não é a última. Avançando para próxima pergunta.",
      ); // Log
      // Se acertou, mas não é a última, avança a pergunta
      setState(() {
        currentQuestionIndex++;
        // Garante que o índice é válido antes de carregar
        if (currentQuestionIndex < quizQuestions.length) {
          _loadCurrentQuestion();
        } else {
          print(
            "QuestaoPage: Erro! Índice da próxima pergunta inválido após acerto.",
          ); // Log erro
          // O que fazer? Salvar progresso parcial? Voltar?
          salvarProgressoENavegar(); // Tenta salvar e voltar como fallback
        }
      });
    } else {
      print("QuestaoPage: Resposta incorreta. Substituindo pergunta."); // Log
      // Se errou, busca uma nova pergunta substituta
      _replaceCurrentQuestion();
    }
  }
  // --- Fim validarResposta ---

  // --- Widgets de Build (sem grandes alterações, apenas verificações) ---
  @override
  Widget build(BuildContext context) {
    // Mostra loading se carregando OU se a lista estiver vazia após carregar
    if (carregando || quizQuestions.isEmpty) {
      print(
        "QuestaoPage build: Showing loading indicator (carregando=$carregando, isEmpty=${quizQuestions.isEmpty})",
      ); // Log
      return Scaffold(
        appBar: AppBar(
          // Adiciona AppBar básico no loading
          backgroundColor: widget.gradientColors.first,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.tipoModuloDisplay.replaceAll("\n", " "),
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: widget.gradientColors.last),
        ),
      );
    }

    // Garante que o índice atual é válido antes de construir a UI
    if (currentQuestionIndex >= quizQuestions.length) {
      print(
        "QuestaoPage build: Error - currentQuestionIndex $currentQuestionIndex out of bounds for quiz size ${quizQuestions.length}. Showing error message.",
      ); // Log erro
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.tipoModuloDisplay.replaceAll("\n", " ")),
        ),
        body: Center(
          child: Text("Erro ao carregar a pergunta $currentQuestionIndex."),
        ),
      );
    }

    final String progressText =
        "Pergunta ${currentQuestionIndex + 1} de ${quizQuestions.length}";
    print(
      "QuestaoPage build: Building UI for question ${currentQuestionIndex + 1}",
    ); // Log

    return Scaffold(
      // AppBar é criado dentro do _buildCustomHeader agora
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
                      minHeight: 6, // Torna a barra um pouco mais espessa
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progressText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ), // Cor mais clara
                    ),
                  ],
                ),
              ),

              // Área de quiz ROLÁVEL
              _buildQuizBody(),

              // Botão ENVIAR FIXO
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para o cabeçalho
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      // Usa Container para permitir padding se necessário
      // padding: const EdgeInsets.only(top: 5), // Pequeno ajuste se a safe area não for suficiente
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () {
              print("QuestaoPage: Back button pressed."); // Log
              Navigator.pop(context); // Apenas fecha a tela
            },
          ),
          // Título centralizado
          Expanded(
            // Usa Expanded para centralizar corretamente
            child: Text(
              widget.tipoModuloDisplay.replaceAll("\n", " "),
              textAlign: TextAlign.center, // Centraliza o texto
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ], // Sombra leve
              ),
            ),
          ),
          // Placeholder para manter o título centralizado
          // Ou pode colocar o botão de config aqui se quiser
          SizedBox(width: 48), // Largura aprox. do IconButton
          /*IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                debugPrint("Configurações clicadas!");
                // Navegar para tela de config?
              },
            ),*/
        ],
      ),
    );
  }

  // Widget para o corpo do quiz (rolável)
  Widget _buildQuizBody() {
    return Expanded(
      // Ocupa o espaço restante
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          children: [
            // Card da pergunta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.95,
                ), // Um pouco menos transparente
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                enunciado,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.4,
                ), // Ajuste de estilo
              ),
            ),
            const SizedBox(height: 20),

            // Alternativas
            ...alternativas.asMap().entries.map((entry) {
              final index = entry.key;
              final texto = entry.value;
              bool isSelected = alternativaSelecionada == index;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(
                            0.8,
                          ), // Mais opaco se não selecionado
                    foregroundColor: Colors.black87, // Cor do texto
                    minimumSize: const Size(
                      double.infinity,
                      55,
                    ), // Altura maior
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(
                              color: widget.gradientColors.last.withOpacity(
                                0.8,
                              ),
                              width: 2.5,
                            ) // Borda mais grossa e colorida
                          : BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ), // Borda fina cinza
                    ),
                    shadowColor: Colors.black.withOpacity(0.2),
                    elevation: isSelected
                        ? 6
                        : 3, // Mais elevação se selecionado
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ), // Padding interno
                  ),
                  onPressed: respostaEnviada
                      ? null
                      : () {
                          // Desabilita se já enviou
                          print(
                            "QuestaoPage: Alternative $index selected.",
                          ); // Log
                          setState(() => alternativaSelecionada = index);
                        },
                  child: Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal, // Negrito se selecionado
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20), // Espaço no final da rolagem
          ],
        ),
      ),
    );
  }

  // WIDGET: Botão Enviar Fixo
  Widget _buildSubmitButton() {
    bool canSubmit = alternativaSelecionada != null && !respostaEnviada;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        8.0,
        16.0,
        16.0,
      ), // Ajuste de padding
      child: ElevatedButton(
        onPressed: canSubmit
            ? validarResposta
            : null, // Desabilita se não puder enviar
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit
              ? Colors.white
              : Colors.grey.shade300, // Cor muda se desabilitado
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: canSubmit
              ? widget.gradientColors.first
              : Colors.grey.shade600,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black.withOpacity(0.4),
          elevation: canSubmit ? 6 : 2, // Menos elevação se desabilitado
        ),
        child: Text(
          respostaEnviada ? "AGUARDE..." : "ENVIAR", // Texto muda
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
} // Fim da classe _QuestaoPageState
