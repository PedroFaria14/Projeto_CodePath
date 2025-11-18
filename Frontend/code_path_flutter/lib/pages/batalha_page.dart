// Arquivo: batalha_page.dart
// 🚀 MIX: Múltipla Escolha, Word Bank e Drag & Drop

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:codepath/providers/user_provider.dart';
import 'package:collection/collection.dart';
import 'resultado_dialog.dart';

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
  bool respostaEnviada = false;

  Timer? _timer;
  final int _tempoTotalBatalha = 120;
  int _segundosRestantes = 120;
  final Stopwatch _stopwatch = Stopwatch();
  String _userEmail = "";
  final String _baseUrl = "https://projeto-codepath.onrender.com";

  // Estados Gerais
  String _perguntaTipoAtual = "";

  // Fase 1 (Multipla Escolha)
  int? alternativaSelecionada;

  // Fase 2 (Word Bank)
  String _fase2Enunciado = "";
  String _fase2Dica = "";
  List<String> _palavrasSelecionadas = [];
  List<String> _palavrasDisponiveis = [];

  // Fase 3 (Drag & Drop)
  String _fase3Titulo = "";
  List<String> _blocosParaOrdenar = [];
  List<String> _blocosOrdemCorreta = [];

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
          setState(() => _segundosRestantes--);
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

    setState(() {
      respostaEnviada = false;
      // Detecta o tipo (se não vier, assume drag_and_drop por segurança)
      _perguntaTipoAtual = pergunta["tipo"] ?? "multipla_escolha";

      if (_perguntaTipoAtual == "multipla_escolha") {
        alternativaSelecionada = null;
        // Opções já vêm do backend
      } else if (_perguntaTipoAtual == "codigo_snippet_word_bank") {
        _fase2Enunciado = pergunta["texto_pergunta"] ?? "";
        _fase2Dica = pergunta["dica"] ?? "";
        _palavrasSelecionadas.clear();
        final List<String> banco = List<String>.from(
          pergunta["palavras_banco"] ?? [],
        );
        banco.shuffle();
        _palavrasDisponiveis = banco;
      } else if (_perguntaTipoAtual == "drag_and_drop") {
        _fase3Titulo = pergunta["titulo"] ?? "";
        _blocosOrdemCorreta = List<String>.from(
          pergunta["partes_codigo"] ?? [],
        );
        _blocosParaOrdenar = List<String>.from(_blocosOrdemCorreta);
        _blocosParaOrdenar.shuffle();
      }
    });
  }

  void _validarResposta() {
    if (respostaEnviada) return;

    final perguntaAtual = quizQuestions[currentQuestionIndex];
    bool correta = false;

    if (_perguntaTipoAtual == "multipla_escolha") {
      if (alternativaSelecionada == null) return;
      final opcoes = List<String>.from(perguntaAtual["opcoes"]);
      final escolhida = opcoes[alternativaSelecionada!];
      correta = (escolhida == perguntaAtual["resposta_correta"]);
    } else if (_perguntaTipoAtual == "codigo_snippet_word_bank") {
      final respostaUsuario = _palavrasSelecionadas.join("");
      final respostaCorreta = (perguntaAtual["resposta_correta"] ?? "")
          .replaceAll(' ', '');
      correta = (respostaUsuario.replaceAll(' ', '') == respostaCorreta);
    } else if (_perguntaTipoAtual == "drag_and_drop") {
      correta = const ListEquality().equals(
        _blocosParaOrdenar,
        _blocosOrdemCorreta,
      );
    }

    setState(() {
      respostaEnviada = true;
      if (correta) acertos++;
    });

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

    if (porTempo) setState(() => respostaEnviada = true);

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
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String statusFinal = data["status_final"] ?? "CONCLUIDO";
        final String mensagem = data["message"] ?? "Batalha Concluída!";
        final int rankChange = (data["rank_change"] as num? ?? 0).toInt();
        final int moedasGanhas = (data["moedas_ganhas"] as num? ?? 0).toInt();

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
        throw Exception("Erro ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Erro ao finalizar: $e");
      _showResultadoFinalDialog("ERRO", "Erro de conexão", 0, 0);
    }
  }

  void _showResultadoFinalDialog(
    String status,
    String msg,
    int rank,
    int moedas,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ResultadoFinalDialog(
        status: status,
        mensagem: msg,
        rankChange: rank,
        moedasGanhas: moedas,
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
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 5),
                Text(
                  _tempoFormatado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
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
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: LinearProgressIndicator(
                        value:
                            (currentQuestionIndex + 1) / quizQuestions.length,
                        backgroundColor: Colors.white38,
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
    Widget questionWidget;
    if (_perguntaTipoAtual == "multipla_escolha") {
      questionWidget = _buildMultipleChoice();
    } else if (_perguntaTipoAtual == "codigo_snippet_word_bank") {
      questionWidget = _buildWordBank();
    } else if (_perguntaTipoAtual == "drag_and_drop") {
      questionWidget = _buildDragAndDrop();
    } else {
      questionWidget = const Center(child: Text("Erro de Tipo"));
    }
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: questionWidget,
      ),
    );
  }

  // --- WIDGETS ESPECÍFICOS ---

  Widget _buildMultipleChoice() {
    final pergunta = quizQuestions[currentQuestionIndex];
    final opcoes = List<String>.from(pergunta["opcoes"] ?? []);
    final enunciado = pergunta["pergunta"] ?? "";

    return Column(
      children: [
        _buildModernCard(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              enunciado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...opcoes.asMap().entries.map((entry) {
          final idx = entry.key;
          final txt = entry.value;
          final isSelected = alternativaSelecionada == idx;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: respostaEnviada
                  ? null
                  : () => setState(() => alternativaSelecionada = idx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.white : Colors.white70,
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? const BorderSide(color: Colors.green, width: 3)
                      : BorderSide.none,
                ),
              ),
              child: Text(txt, style: const TextStyle(fontSize: 16)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWordBank() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModernCard(
          Padding(
            padding: const EdgeInsets.all(8),
            child: const Text(
              "Complete o Código",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildModernCard(
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Text(
              _fase2Enunciado.replaceAll("____", " [ ___ ] "),
              style: GoogleFonts.sourceCodePro(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Caixa de Resposta
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: _palavrasSelecionadas.isEmpty
              ? const Center(
                  child: Text(
                    "Toque nas palavras...",
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _palavrasSelecionadas
                      .map(
                        (p) => Chip(
                          label: Text(
                            p,
                            style: GoogleFonts.sourceCodePro(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onDeleted: () {
                            if (respostaEnviada) return;
                            setState(() {
                              _palavrasSelecionadas.remove(p);
                              _palavrasDisponiveis.add(p);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
        const Divider(height: 30, thickness: 1),
        // Botões
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _palavrasDisponiveis
              .map(
                (p) => OutlinedButton(
                  onPressed: () {
                    if (respostaEnviada) return;
                    setState(() {
                      _palavrasDisponiveis.remove(p);
                      _palavrasSelecionadas.add(p);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: Text(
                    p,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDragAndDrop() {
    return Column(
      children: [
        _buildModernCard(
          Padding(
            padding: const EdgeInsets.all(8),
            child: const Text(
              "Organize o Código",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _fase3Titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _blocosParaOrdenar.length,
            itemBuilder: (ctx, idx) {
              final code = _blocosParaOrdenar[idx];
              return Card(
                key: ValueKey(code),
                elevation: 2,
                margin: const EdgeInsets.all(6),
                child: ListTile(
                  title: Text(
                    code,
                    style: GoogleFonts.sourceCodePro(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.drag_handle),
                ),
              );
            },
            onReorder: (oldIdx, newIdx) {
              if (respostaEnviada) return;
              setState(() {
                if (newIdx > oldIdx) newIdx -= 1;
                final item = _blocosParaOrdenar.removeAt(oldIdx);
                _blocosParaOrdenar.insert(newIdx, item);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = false;
    if (!respostaEnviada) {
      if (_perguntaTipoAtual == "multipla_escolha")
        canSubmit = alternativaSelecionada != null;
      else if (_perguntaTipoAtual == "codigo_snippet_word_bank")
        canSubmit = _palavrasSelecionadas.isNotEmpty;
      else if (_perguntaTipoAtual == "drag_and_drop")
        canSubmit = true;
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: canSubmit ? _validarResposta : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? Colors.white : Colors.grey,
          foregroundColor: canSubmit ? Colors.green : Colors.black54,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          respostaEnviada ? "AGUARDE..." : "ENVIAR",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildModernCard(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

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
    final color = acertou ? Colors.green : Colors.red;
    return AlertDialog(
      title: Text(
        acertou ? "Correto!" : "Incorreto!",
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      content: Icon(
        acertou ? Icons.check_circle : Icons.cancel,
        color: color,
        size: 60,
      ),
      actions: [
        ElevatedButton(
          onPressed: onClose,
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: Text(
            isLastQuestion ? "FINALIZAR" : "PRÓXIMO",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
