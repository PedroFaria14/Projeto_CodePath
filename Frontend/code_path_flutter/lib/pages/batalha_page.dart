// Arquivo: batalha_page.dart (Atualizado com Provider)

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'resultado_dialog.dart';

// 🚀 IMPORTS DO PROVIDER
import 'package:provider/provider.dart';
import 'package:codepath/providers/user_provider.dart';

class BatalhaPage extends StatefulWidget {
  final List<Map<String, dynamic>> perguntas;
  final String tipoBatalha;
  final String? idBatalhaOponente;
  final int? pontuacaoOponente;
  final String? idConvite;

  const BatalhaPage({
    super.key,
    required this.perguntas,
    required this.tipoBatalha,
    this.idBatalhaOponente,
    this.pontuacaoOponente,
    this.idConvite,
  });

  @override
  State<BatalhaPage> createState() => _BatalhaPageState();
}

class _BatalhaPageState extends State<BatalhaPage> {
  List<Map<String, dynamic>> quizQuestions = [];
  int currentQuestionIndex = 0;
  int acertos = 0;
  bool carregando = true;
  String enunciado = "";
  List<String> alternativas = [];
  String respostaCorreta = "";
  int? alternativaSelecionada;
  bool respostaEnviada = false;
  Timer? _timer;
  final int _tempoTotalBatalha = 120; // 2 minutos
  int _segundosRestantes = 120;
  final Stopwatch _stopwatch = Stopwatch();
  String _userEmail = "";
  final String _baseUrl = "https://projeto-codepath.onrender.com";

  @override
  void initState() {
    super.initState();
    _iniciarBatalha();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _iniciarBatalha() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString("userEmail") ?? "";
    if (_userEmail.isEmpty || widget.perguntas.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      quizQuestions = widget.perguntas;
      carregando = false;
    });
    _loadCurrentQuestion();
    _iniciarTimer();
    _stopwatch.start();
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        if (mounted) {
          setState(() {
            _segundosRestantes--;
          });
        }
      } else {
        timer.cancel();
        _finalizarBatalha(porTempo: true);
      }
    });
  }

  String get _tempoFormatado {
    final int minutes = _segundosRestantes ~/ 60;
    final int seconds = _segundosRestantes % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _loadCurrentQuestion() {
    if (currentQuestionIndex >= quizQuestions.length) {
      _finalizarBatalha(porTempo: false);
      return;
    }
    final pergunta = quizQuestions[currentQuestionIndex];
    List<String> opcoesEmbaralhadas = List<String>.from(
      pergunta["opcoes"] ?? [],
    );
    opcoesEmbaralhadas.shuffle();
    setState(() {
      enunciado = pergunta["pergunta"] ?? "Erro: Pergunta não encontrada";
      alternativas = opcoesEmbaralhadas;
      respostaCorreta = pergunta["resposta_correta"] ?? "";
      alternativaSelecionada = null;
      respostaEnviada = false;
    });
  }

  void _validarResposta() {
    if (alternativaSelecionada == null || respostaEnviada) return;
    setState(() => respostaEnviada = true);

    final String respostaSelecionada = alternativas[alternativaSelecionada!];
    final bool correta = (respostaSelecionada == respostaCorreta);

    if (correta) {
      setState(() {
        acertos++;
      });
    }

    final bool isLast = currentQuestionIndex == quizQuestions.length - 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _BatalhaFeedbackModal(
          acertou: correta,
          isLastQuestion: isLast,
          onClose: () {
            Navigator.pop(dialogContext);

            if (isLast) {
              _finalizarBatalha(porTempo: false);
            } else {
              setState(() {
                currentQuestionIndex++;
              });
              _loadCurrentQuestion();
            }
          },
        );
      },
    );
  }

  Future<void> _finalizarBatalha({bool porTempo = false}) async {
    _timer?.cancel();
    _stopwatch.stop();
    final double tempoGasto = _stopwatch.elapsedMilliseconds / 1000.0;

    if (porTempo) {
      setState(() {
        respostaEnviada = true;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Enviando placar..."),
          ],
        ),
      ),
    );

    try {
      String endpoint = "";
      Map<String, dynamic> body = {};

      if (widget.tipoBatalha == "ALEATORIA") {
        endpoint = "/batalha/finalizar";
        body = {
          "email": _userEmail,
          "pontuacao": acertos,
          "tempo_gasto_segundos": tempoGasto,
          "id_batalha_oponente": widget.idBatalhaOponente,
          "pontuacao_oponente": widget.pontuacaoOponente,
        };
      } else {
        // "CONVITE"
        endpoint = "/convite/finalizar";
        body = {
          "id_convite": widget.idConvite,
          "email_jogador": _userEmail,
          "pontuacao": acertos,
          "tempo_gasto_segundos": tempoGasto,
        };
      }

      final response = await http.post(
        Uri.parse("$_baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      Navigator.pop(context); // Fecha o loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String statusFinal = data["status_final"] ?? "CONCLUIDO";
        final String mensagem = data["message"] ?? "Batalha Concluída!";
        final int rankChange = (data["rank_change"] as num? ?? 0).toInt();
        final int moedasGanhas = (data["moedas_ganhas"] as num? ?? 0).toInt();

        // 🚀 AQUI ESTÁ A ATUALIZAÇÃO
        // Atualiza o estado global ANTES de mostrar o pop-up
        // Isso só afeta resultados imediatos (não os "aguardando")
        if (statusFinal != "AGUARDANDO_OPONENTE") {
          Provider.of<UserProvider>(
            context,
            listen: false,
          ).applyBattleRewards(rankChange, moedasGanhas);
        }

        _showResultadoFinalDialog(
          statusFinal,
          mensagem,
          rankChange,
          moedasGanhas,
        );
      } else {
        throw Exception("Erro ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Fecha o loading
      print("Erro ao finalizar batalha: $e");
      _showResultadoFinalDialog("ERRO", "Erro ao enviar placar: $e", 0, 0);
    }
  }

  void _showResultadoFinalDialog(
    String status,
    String mensagem,
    int rankChange,
    int moedasGanhas,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ResultadoFinalDialog(
        status: status,
        mensagem: mensagem,
        rankChange: rankChange,
        moedasGanhas: moedasGanhas,
        onClose: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String progressText = (quizQuestions.isEmpty)
        ? ""
        : "Pergunta ${currentQuestionIndex + 1} de ${quizQuestions.length}";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              "Acertos: $acertos",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              progressText,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () {
            // TODO: Adicionar um "Tem certeza que quer desistir?"
            Navigator.pop(context);
          },
        ),
        actions: [
          // Timer
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 5),
                Text(
                  _tempoFormatado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFA8E6CF),
              Color(0xFFDCEDC1),
              Color(0xFFFFF3B0),
              Color(0xFFFFD3B6),
            ],
          ),
        ),
        child: SafeArea(
          child: carregando
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3CB371)),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: LinearProgressIndicator(
                        value:
                            (currentQuestionIndex + 1) / quizQuestions.length,
                        backgroundColor: Colors.white.withOpacity(0.4),
                        color: const Color(0xFF3CB371),
                        minHeight: 6,
                      ),
                    ),
                    _buildQuizBody(),
                    _buildSubmitButton(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuizBody() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          children: [
            _buildModernCard(
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  enunciado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
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
                        : Colors.white.withOpacity(0.8),
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(
                              color: Color(0xFF3CB371),
                              width: 2.5,
                            )
                          : BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    shadowColor: Colors.black.withOpacity(0.2),
                    elevation: isSelected ? 6 : 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: respostaEnviada
                      ? null
                      : () {
                          setState(() => alternativaSelecionada = index);
                        },
                  child: Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = alternativaSelecionada != null && !respostaEnviada;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: ElevatedButton(
        onPressed: canSubmit ? _validarResposta : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? Colors.white : Colors.grey.shade300,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: canSubmit
              ? const Color(0xFF3CB371)
              : Colors.grey.shade600,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black.withOpacity(0.4),
          elevation: canSubmit ? 6 : 2,
        ),
        child: Text(
          respostaEnviada ? "AGUARDE..." : "ENVIAR",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildModernCard(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Padding(padding: const EdgeInsets.all(12.0), child: child),
        ),
      ),
    );
  }
}

// --- WIDGET DE MODAL SIMPLIFICADO ---
class _BatalhaFeedbackModal extends StatelessWidget {
  final bool acertou;
  final bool isLastQuestion;
  final VoidCallback onClose;

  const _BatalhaFeedbackModal({
    required this.acertou,
    required this.isLastQuestion,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = acertou
        ? Colors.green.shade700
        : Colors.red.shade700;
    final String title = acertou ? "Correto!" : "Incorreto!";
    final String buttonText = isLastQuestion ? "FINALIZAR" : "PRÓXIMA PERGUNTA";

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      ),
      content: Icon(
        acertou ? Icons.check_circle : Icons.cancel,
        color: primaryColor,
        size: 60,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: onClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }
}
