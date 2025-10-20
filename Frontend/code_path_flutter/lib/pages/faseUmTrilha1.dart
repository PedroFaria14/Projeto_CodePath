import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'trilhaUm.dart'; // Importa a tela do mapa
// import '../main.dart'; // Descomente se usar RouteObserver

// Variáveis de estado do Quiz
const int QUIZ_SIZE = 3;

// --- Widget ExplicacaoModal ---
class ExplicacaoModal extends StatelessWidget {
  final bool acertou;
  final String explicacao;
  final int faseId;
  final VoidCallback onClose;
  final bool isLastQuestion; // Flag para mudar a mensagem final

  const ExplicacaoModal({
    super.key,
    required this.acertou,
    required this.explicacao,
    required this.faseId,
    required this.onClose,
    this.isLastQuestion = false,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos as cores base
    final Color primaryColor = acertou
        ? Colors.green.shade700
        : Colors.red.shade700;
    final Color lightBackground = acertou
        ? Colors.green.shade100
        : Colors.red.shade100;

    final String title = acertou
        ? (isLastQuestion ? "Fase Concluída! 🎉" : "Resposta Correta! ")
        // Mensagem quando erra: a pergunta será substituída
        : "Ops! Resposta Incorreta";
    final String imageAsset = "assets/imagens/gato1.png";

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: lightBackground,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20),
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor,
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
            Image.asset(imageAsset, height: 70),
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
                // Texto do botão que reflete o estado do quiz
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

class QuestaoPage extends StatefulWidget {
  final int faseId;
  final String tipoModulo;

  const QuestaoPage({
    super.key,
    required this.faseId,
    required this.tipoModulo,
  });

  @override
  State<QuestaoPage> createState() => _QuestaoPageState();
}

class _QuestaoPageState extends State<QuestaoPage> {
  // 💥 NOVO ESTADO DO QUIZ
  List<Map<String, dynamic>> quizQuestions = []; // Lista de 3 perguntas
  int currentQuestionIndex = 0; // Índice da pergunta atual
  int correctAnswers =
      0; // Contador de acertos (não usado, mas bom para future features)

  // 💥 Variáveis da Pergunta ATUAL
  String enunciado = "";
  List<String> alternativas = [];
  String idPergunta =
      ""; // idPergunta é a ID que vai para o endpoint /responder

  bool carregando = true;
  int? alternativaSelecionada;
  bool respostaEnviada = false; // Bloqueia botões após envio

  @override
  void initState() {
    super.initState();
    carregarNovoQuiz(); // Carrega o conjunto inicial de 3 perguntas
  }

  // 💥 FUNÇÃO AUXILIAR: Busca N perguntas (para quiz inicial)
  Future<void> carregarNovoQuiz() async {
    return _fetchQuestions(QUIZ_SIZE);
  }

  // 💥 FUNÇÃO AUXILIAR: Busca e substitui uma única pergunta
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
          // Apenas reinicia o contador se for um quiz novo
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

      // 🚀 Chamada de API: Passa o 'count' para o backend
      final response = await http.get(
        Uri.parse(
          "http://10.0.2.2:8000/pergunta/?nivel=$nivelFirebase&tipo=${Uri.encodeComponent(widget.tipoModulo)}&count=$count",
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
            // 💥 Substitui APENAS a pergunta atual pela nova
            quizQuestions[currentQuestionIndex] = Map<String, dynamic>.from(
              novasPerguntas.first,
            );
          } else {
            // Define o quiz inicial (3 perguntas)
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

  // 💥 NOVA FUNÇÃO: Carrega os dados da pergunta atual para o estado
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

  // 💥 FUNÇÃO MODIFICADA: Salva progresso e navega (Fluxo de SUCESSO DO QUIZ)
  Future<void> salvarProgressoENavegar() async {
  // 1. Lógica de salvar progresso (adaptada para o novo fluxo)
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString("userEmail");
  if (email == null) return;
  
  // Busca perfil para obter o estado atual de todas as fases
  final profileResp = await http.get(Uri.parse("http://10.0.2.2:8000/profile/$email"));
  final profileData = jsonDecode(profileResp.body);
  final user = profileData["user"] ?? profileData;
  
  // Montagem do payload com o formato Mapa Aninhado (corrigido)
  Map<String, dynamic> fasesMap = Map<String, dynamic>.from(user["fases"] ?? {});
  List<Map<String, dynamic>> moduleFases = [];
  if (fasesMap.containsKey(widget.tipoModulo)) {
      moduleFases = List<Map<String, dynamic>>.from(fasesMap[widget.tipoModulo]);
  } else {
      // Fallback
      moduleFases = List.generate(
        QUIZ_SIZE,
        (i) => {"id": i + 1, "liberada": i == 0, "atual": i == 0},
      );
  }
  
  // 4) Atualiza o módulo atual (faseAtual = widget.faseId)
  int faseCompletadaId = widget.faseId;
  int proximaFaseId = faseCompletadaId + 1;
  
  // Condição para verificar se a próxima fase é a última da lista
  bool trilhaCompletada = proximaFaseId > moduleFases.length;
  
  for (var fase in moduleFases) {
    // 1. Limpa o status 'atual' em todos os nós
    fase["atual"] = false;

    // 2. Garante que a fase recém-completada seja marcada como liberada (estrela)
    if (fase["id"] == faseCompletadaId) {
        fase["liberada"] = true; 
    }
    
    // 3. 🚀 MARCA O PRÓXIMO NÓ COMO ATUAL E LIBERADO
    if (fase["id"] == proximaFaseId) {
        fase["atual"] = true; 
        fase["liberada"] = true; // Deve ser liberada para ser clicável
    }
  }

  // 🚀 CORREÇÃO PRINCIPAL: Se a trilha for completada, marca o ÚLTIMO nó como ATUAL
  if (trilhaCompletada) {
      if (moduleFases.isNotEmpty) {
          // O gatinho deve ficar no último nó que o usuário completou
          moduleFases.last["atual"] = true; 
      }
  }

  fasesMap[widget.tipoModulo] = moduleFases;
  
  // O payload deve enviar APENAS a lista do módulo que o backend espera
  final payload = {"email": email, "tipo": widget.tipoModulo, "fases": moduleFases};

  await http.post(
    Uri.parse("http://10.0.2.2:8000/salvar_progresso"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(payload),
  );
  
  // 2. Navegação de volta para o mapa (TrilhaUm)
  final response = await http.get(Uri.parse("http://10.0.2.2:8000/profile/$email"));
  final data = jsonDecode(response.body);
  final userNovo = data["user"];

  final Map<String, dynamic> fasesMapNovo = Map<String, dynamic>.from(userNovo["fases"] ?? {});
  final List fasesAtualizadas = List<Map<String, dynamic>>.from(fasesMapNovo[widget.tipoModulo] ?? []);
  
  if (!mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => TrilhaUm(
        tipoModulo: widget.tipoModulo,
        fases: fasesAtualizadas,
      ),
    ),
    (route) => false,
  );
}

  // 💥 FUNÇÃO MODIFICADA: Gerencia a submissão, modal e progresso/avanço
  void validarResposta() async {
    if (alternativaSelecionada == null || respostaEnviada) return;

    setState(() => respostaEnviada = true); // Bloqueia o botão

    final String respostaSelecionada = alternativas[alternativaSelecionada!];

    // Faz a requisição para o endpoint /responder
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/responder"),
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

    if (correta) {
      // Não usamos mais correctAnswers para avançar, mas mantemos para logs/futuro
      // correctAnswers++;
    }

    final bool isLast = currentQuestionIndex == quizQuestions.length - 1;

    // 1. Exibir o Modal de Explicação
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
            Navigator.pop(dialogContext); // Fecha o modal
          },
        );
      },
    );

    // 2. Processamento do Progresso / Avanço
    if (correta && isLast) {
      // Condição de SUCESSO: Acertou a última pergunta
      salvarProgressoENavegar();
    } else if (correta && !isLast) {
      // Acertou, mas tem mais perguntas: avança para a próxima
      setState(() {
        currentQuestionIndex++;
        _loadCurrentQuestion(); // Carrega os dados da próxima pergunta
      });
    } else {
      // 💥 Condição de FALHA: Substitui a pergunta atual por uma nova
      _replaceCurrentQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando || quizQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Informação de progresso visual
    final String progressText =
        "Pergunta ${currentQuestionIndex + 1} de ${quizQuestions.length}";

    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Fase ${widget.faseId} - ${widget.tipoModulo}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // NOVO: Indicador de progresso do quiz
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / quizQuestions.length,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              progressText,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            Image.asset("assets/imagens/gato1.png", height: 80),
            const SizedBox(height: 12),
            Text(
              enunciado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              // Usa Expanded para gerenciar o espaço das alternativas
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...alternativas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final texto = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: alternativaSelecionada == index
                                ? Colors.green.shade400
                                : Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              // Adiciona borda de destaque se selecionado
                              side: alternativaSelecionada == index
                                  ? BorderSide(
                                      color: Colors.green.shade800,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          // Botão desativado se a resposta já foi enviada
                          onPressed: respostaEnviada
                              ? null
                              : () {
                                  setState(
                                    () => alternativaSelecionada = index,
                                  );
                                },
                          child: Text(texto),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: alternativaSelecionada == null || respostaEnviada
                  ? null
                  : validarResposta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                respostaEnviada ? "PROCESSANDO..." : "Enviar",
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
