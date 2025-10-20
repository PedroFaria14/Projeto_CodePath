import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'trilhaUm.dart'; // Importa a tela do mapa

// Variáveis de estado do Quiz
const int QUIZ_SIZE = 3;

// --- Widget ExplicacaoModal (SEM MUDANÇAS AQUI) ---
class ExplicacaoModal extends StatelessWidget {
  final bool acertou;
  final String explicacao;
  final int faseId;
  final VoidCallback onClose;
  final bool isLastQuestion;
  final List<Color> gradientColors;

  const ExplicacaoModal({
    super.key,
    required this.acertou,
    required this.explicacao,
    required this.faseId,
    required this.onClose,
    this.isLastQuestion = false,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    // ... (código do modal continua o mesmo) ...
     final Color primaryColor = acertou
        ? Colors.green.shade700
        : Colors.red.shade700;
    final Color lightBackground = acertou
        ? Colors.green.shade100
        : Colors.red.shade100;

    final String title = acertou
        ? (isLastQuestion ? "Fase Concluída! " : "Resposta Correta! ")
        : "Ops! Resposta Incorreta";
    final String imageAsset = "assets/imagens/gato1.png"; // Gato padrão para feedback

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
                backgroundColor: primaryColor, // Botão verde/vermelho
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


// Clipper para a curva (pode ajustar a forma aqui se necessário)
class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40); // Começa mais acima
    // Curva mais larga e suave
    path.quadraticBezierTo(size.width / 2, size.height + 20, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class QuestaoPage extends StatefulWidget {
  final int faseId;
  final String tipoModulo; // API
  final String backgroundAsset; // Não usado mais para fundo, mas mantido
  final List<Offset> posicoes; // Não usado mais para fundo, mas mantido
  final String animalAsset;
  final List<Color> gradientColors;
  final String tipoModuloDisplay; // Exibição

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
  // ... (Variáveis de estado - sem mudanças) ...
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

  // ... (Funções carregarNovoQuiz, _replaceCurrentQuestion, _fetchQuestions, _loadCurrentQuestion - sem mudanças) ...
  Future<void> carregarNovoQuiz() async { /* ... */ }
  Future<void> _replaceCurrentQuestion() async { /* ... */ }
  Future<void> _fetchQuestions(int count, {bool isReplacement = false}) async { /* ... */ }
  void _loadCurrentQuestion() { /* ... */ }

  // ... (Função salvarProgressoENavegar - sem mudanças) ...
  Future<void> salvarProgressoENavegar() async { /* ... */ }

  // ... (Função validarResposta - sem mudanças, exceto o showDialog) ...
  void validarResposta() async {
    if (alternativaSelecionada == null || respostaEnviada) return;

    setState(() => respostaEnviada = true); // Bloqueia o botão

    final String respostaSelecionada = alternativas[alternativaSelecionada!];

    late final http.Response response; // Declarado aqui fora para garantir o escopo
    try {
      response = await http.post(
        Uri.parse("http://10.0.2.2:8000/responder"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idPergunta": idPergunta,
          "resposta": respostaSelecionada,
        }),
      );

      if (response.statusCode != 200) {
        if (!mounted) return; // Checa se o widget ainda está na árvore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao validar resposta. Tente novamente."),
          ),
        );
        setState(() => respostaEnviada = false);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de conexão: $e")),
      );
      setState(() => respostaEnviada = false);
      return;
    }

    // --- VARIÁVEIS DECLARADAS AQUI ---
    // Elas estão no escopo correto da função agora.
    final Map<String, dynamic> data = jsonDecode(response.body);
    final bool correta = data["success"] ?? false;
    final String explicacao = data["explicacao"] ?? "A explicação não foi retornada.";
    final bool isLast = currentQuestionIndex == quizQuestions.length - 1;
    // --- FIM DA DECLARAÇÃO ---

    // Checa o 'mounted' ANTES do showDialog
    if (!mounted) return;

    // 1. Exibir o Modal de Explicação
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // As variáveis 'correta', 'explicacao', e 'isLast' devem ser visíveis aqui
        return ExplicacaoModal(
          acertou: correta,
          explicacao: explicacao,
          faseId: widget.faseId,
          isLastQuestion: isLast,
          onClose: () {
            Navigator.pop(dialogContext); // Fecha o modal
          },
          gradientColors: widget.gradientColors,
        );
      },
    );

    // Checa o 'mounted' DEPOIS do showDialog
    if (!mounted) return;

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
      // Tela de Loading com o fundo do módulo
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    final String progressText =
        "Pergunta ${currentQuestionIndex + 1} de ${quizQuestions.length}";

    // Cores principais para estilização
    final Color corPrincipalEscura = widget.gradientColors.first;
    final Color corPrincipalClara = widget.gradientColors.length > 1 ? widget.gradientColors.last : widget.gradientColors.first;

    return Scaffold(
      // 🚀 MUDANÇA: Fundo branco padrão, o gradiente vai ficar só na parte de cima
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // AppBar simples e transparente (como antes)
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column( // 🚀 MUDANÇA: Estrutura principal é uma Column
        children: [
          // 1. Parte Superior Colorida com Curva
          ClipPath(
            clipper: BottomCurveClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.40, // Altura da seção colorida
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea( // Conteúdo dentro da área segura
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // Alinha no topo
                  children: [
                    const SizedBox(height: 50), // Espaço para o AppBar
                    // 🚀 MUDANÇA: Tamanho do Animal reduzido
                    Image.asset(
                      widget.animalAsset,
                      height: 80, // Animal menor
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 15),
                    // Progresso
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0), // Padding lateral
                      child: LinearProgressIndicator(
                        value: (currentQuestionIndex + 1) / quizQuestions.length,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        color: Colors.white,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                     const SizedBox(height: 8),
                     Text(
                       progressText,
                       style: const TextStyle(fontSize: 14, color: Colors.white70),
                     ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Conteúdo Rolável (Card da Pergunta, Alternativas, Botão)
          Expanded( // Ocupa o espaço restante
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 24.0), // Ajusta padding
              child: Column(
                children: [
                  // Card da Pergunta
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25), // Padding interno
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20), // Mais arredondado
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3), // Sombra mais suave
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Exercício de ${widget.tipoModuloDisplay.replaceAll('\n', ' ')}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18, // Ligeiramente menor
                            fontWeight: FontWeight.bold,
                            color: corPrincipalEscura,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          enunciado,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                        ),
                        // --- Bloco de Código (Estilizado como na referência) ---
                        if (true) // Adapte a condição
                         Padding(
                           padding: const EdgeInsets.only(top: 15.0),
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                             width: double.infinity,
                             decoration: BoxDecoration(
                               color: corPrincipalEscura, // Cor escura do gradiente
                               borderRadius: BorderRadius.circular(10),
                             ),
                             child: Text(
                               "for i in range(5, 0, -1):\n  print(___)", // Exemplo
                               style: const TextStyle(
                                 color: Colors.white, // Texto branco
                                 fontFamily: 'monospace',
                                 fontSize: 15,
                                 height: 1.5,
                               ),
                             ),
                           ),
                         ),
                        // --- Fim do Bloco de Código ---
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Alternativas
                  ...alternativas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final texto = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: alternativaSelecionada == index
                              ? corPrincipalClara.withOpacity(0.95) // Quase opaco selecionado
                              : Colors.white, // Fundo branco padrão
                          foregroundColor: corPrincipalEscura, // Texto escuro
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                             side: BorderSide( // Borda escura sempre visível
                               color: alternativaSelecionada == index ? corPrincipalEscura : corPrincipalClara,
                               width: alternativaSelecionada == index ? 2.5 : 1.5,
                              ),
                          ),
                          elevation: alternativaSelecionada == index ? 6 : 3, // Elevação muda
                           shadowColor: Colors.grey.withOpacity(0.5),
                        ),
                        onPressed: respostaEnviada ? null : () {
                          setState(() => alternativaSelecionada = index);
                        },
                        child: Text(
                          texto,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 30),

                  // Botão Enviar
                  ElevatedButton(
                    onPressed: alternativaSelecionada == null || respostaEnviada ? null : validarResposta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corPrincipalClara, // Cor clara
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),
                      elevation: 6,
                    ),
                    child: Text(
                      respostaEnviada ? "PROCESSANDO..." : "Enviar",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Texto branco
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Espaço no final
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}