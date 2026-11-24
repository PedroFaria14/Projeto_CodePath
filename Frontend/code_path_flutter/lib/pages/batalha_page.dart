import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:codepath/core/api_http.dart' as http;
import 'package:codepath/core/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool respostaEnviada = false;
  bool _finalizando = false;
  bool _finalizada = false;
  DateTime? _deadline;

  Timer? _timer;
  int _segundosRestantes = 120;
  final Stopwatch _stopwatch = Stopwatch();
  String _userEmail = "";
  final String _baseUrl = AppConfig.apiBaseUrl;

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
    if (!mounted) return;
    if (_userEmail.isEmpty || widget.perguntas.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      quizQuestions = widget.perguntas;
    });
    await _iniciarTimer();
    _stopwatch.start();
  }

  Future<void> _iniciarTimer() async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/game/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'attempt_id': quizQuestions.first['attempt_id']}));
      if (!mounted || _finalizando || _finalizada) return;
      if (response.statusCode != 200) {
        throw http.ApiException(http.errorMessage(response, 'Não foi possível iniciar a partida.'));
      }
      final data = jsonDecode(response.body);
      _deadline = DateTime.parse(data['deadline'] as String);
      setState(() {
        currentQuestionIndex = (data['next_index'] as num).toInt();
        acertos = (data['score'] as num).toInt();
        _segundosRestantes = _deadline!.difference(DateTime.now()).inSeconds.clamp(0, 120);
        carregando = false;
      });
      _loadCurrentQuestion();
      if (_finalizando || _finalizada) return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is http.ApiException ? error.message : 'Não foi possível iniciar a partida.'),
        action: SnackBarAction(label: 'Tentar novamente', onPressed: _iniciarTimer),
      ));
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _deadline!.difference(DateTime.now()).inSeconds.clamp(0, 120);
      if (remaining > 0) {
        if (mounted) {
          setState(() => _segundosRestantes = remaining);
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
      _perguntaTipoAtual = pergunta["tipo"] ?? "multipla_escolha";

      if (_perguntaTipoAtual == "multipla_escolha") {
        alternativaSelecionada = null;
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

  Future<void> _validarResposta() async {
    if (respostaEnviada || _finalizando || _finalizada) return;
    final perguntaAtual = quizQuestions[currentQuestionIndex];
    Object answer;
    if (_perguntaTipoAtual == 'multipla_escolha') {
      if (alternativaSelecionada == null) return;
      answer = (perguntaAtual['opcoes'] as List)[alternativaSelecionada!];
    } else if (_perguntaTipoAtual == 'codigo_snippet_word_bank') {
      answer = _palavrasSelecionadas.join('');
    } else {
      answer = List<String>.from(_blocosParaOrdenar);
    }
    setState(() => respostaEnviada = true);
    late bool correta;
    try {
      final response = await http.post(Uri.parse('$_baseUrl/game/answer'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'attempt_id': perguntaAtual['attempt_id'], 'index': currentQuestionIndex, 'answer': answer,
        }));
      if (!mounted || _finalizando || _finalizada) return;
      if (response.statusCode != 200) {
        throw http.ApiException(http.errorMessage(response, 'Não foi possível verificar a resposta.'));
      }
      final data = jsonDecode(response.body);
      correta = data['correct'] == true;
      setState(() => acertos = (data['score'] as num).toInt());
    } catch (error) {
      if (!mounted) return;
      // Antes de editar ou reenviar, reconcilia o próximo índice com o servidor.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(minutes: 5),
        content: Text(error is http.ApiException ? error.message : 'Conexão interrompida. Verifique se a resposta foi salva.'),
        action: SnackBarAction(label: 'Verificar envio', onPressed: _iniciarTimer),
      ));
      return;
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
    if (!mounted || _finalizando || _finalizada) return;
    _finalizando = true;
    _timer?.cancel();
    _stopwatch.stop();

    if (porTempo) setState(() => respostaEnviada = true);

    final pageRoute = ModalRoute.of(context);
    if (pageRoute != null) Navigator.of(context).popUntil((route) => route == pageRoute);
    var loadingOpen = true;

    // Loading inicial
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      String endpoint = "";
      Map<String, dynamic> body = {};

      if (widget.tipoBatalha == "ALEATORIA") {
        endpoint = "/batalha/finalizar";
        body = {
          'attempt_id': quizQuestions.first['attempt_id'],
        };
      } else {
        endpoint = "/convite/finalizar";
        body = {
          'attempt_id': quizQuestions.first['attempt_id'],
        };
      }

      final response = await http.post(
        Uri.parse("$_baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      Navigator.pop(context); // Fecha o loading
      loadingOpen = false;

      if (response.statusCode == 200) {
        _finalizada = true;
        final data = jsonDecode(response.body);
        final String statusFinal = data["status_final"] ?? "CONCLUIDO";

        final int rankChange = (data["rank_change"] as num? ?? 0).toInt();
        final int moedasGanhas = (data["moedas_ganhas"] as num? ?? 0).toInt();
        final String mensagem = data["message"] ?? "Aguardando...";

        if (statusFinal != "AGUARDANDO_OPONENTE") {
          await context.read<UserProvider>().loadUserData(_userEmail);
          if (!mounted) return;
        }

        // 🚀 ABRE O DIALOG QUE SE ATUALIZA SOZINHO
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => ResultadoBatalhaDinamico(
            statusInicial: statusFinal,
            mensagemInicial: mensagem,
            rankInicial: rankChange,
            moedasInicial: moedasGanhas,
            userEmail: _userEmail,
            baseUrl: _baseUrl,
            matchId: data['match_id'] as String?,
            // 🚀 CORREÇÃO AQUI: Garante que fecha o dialog e a tela de batalha
            onClose: () {
              Navigator.of(ctx).pop(); // Fecha o Dialog

              // Espera um pouquinho e fecha a tela de batalha
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            },
          ),
        );
      } else {
        throw http.ApiException(http.errorMessage(response, 'Não foi possível enviar o resultado.'));
      }
    } catch (e) {
      if (!mounted) return;
      if (loadingOpen) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is http.ApiException ? e.message : 'Não foi possível enviar o resultado.'),
        action: SnackBarAction(label: 'Tentar novamente', onPressed: () => _finalizarBatalha(porTempo: porTempo)),
      ));
    } finally {
      _finalizando = false;
    }
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
    if (currentQuestionIndex >= quizQuestions.length) {
      return const Expanded(child: Center(child: Text('Todas as respostas foram salvas. Finalizando resultado…')));
    }
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
        if (_fase2Dica.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text('Dica: $_fase2Dica', textAlign: TextAlign.center),
        ),
        const SizedBox(height: 20),
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
          textAlign: TextAlign.center,
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
                  trailing: ReorderableDragStartListener(
                    index: idx,
                    child: const Icon(Icons.drag_handle, size: 30),
                  ),
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
    if (currentQuestionIndex >= quizQuestions.length) return const SizedBox.shrink();
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

// 🚀 WIDGET DINÂMICO (CORRIGIDO)
class ResultadoBatalhaDinamico extends StatefulWidget {
  final String statusInicial;
  final String mensagemInicial;
  final int rankInicial;
  final int moedasInicial;
  final String userEmail;
  final String baseUrl;
  final String? matchId;
  final VoidCallback onClose;

  const ResultadoBatalhaDinamico({
    super.key,
    required this.statusInicial,
    required this.mensagemInicial,
    required this.rankInicial,
    required this.moedasInicial,
    required this.userEmail,
    required this.baseUrl,
    this.matchId,
    required this.onClose,
  });

  @override
  State<ResultadoBatalhaDinamico> createState() =>
      _ResultadoBatalhaDinamicoState();
}

class _ResultadoBatalhaDinamicoState extends State<ResultadoBatalhaDinamico> {
  late String _status;
  late String _mensagem;
  late int _rank;
  late int _moedas;
  Timer? _timer;
  bool _isWaiting = false;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _status = widget.statusInicial;
    _mensagem = widget.mensagemInicial;
    _rank = widget.rankInicial;
    _moedas = widget.moedasInicial;

    if (_status == "AGUARDANDO_OPONENTE") {
      _isWaiting = true;
      _iniciarPolling();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _polling || WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
      _polling = true;
      try {
        final response = await http.get(
          Uri.parse(
            "${widget.baseUrl}/notificacoes/pendentes/${widget.userEmail}",
          ),
        );

        if (response.statusCode == 200) {
          final List data = (jsonDecode(response.body) as List)
              .where((item) => widget.matchId != null && item['match_id'] == widget.matchId).toList();
          if (data.isNotEmpty) {
            timer.cancel();
            final notif = data.first;

            final String titulo = notif['titulo'] ?? "";
            String novoStatus = "VITORIA";
            if (titulo.toUpperCase().contains("PERDEU")) novoStatus = "DERROTA";
            if (titulo.toUpperCase().contains("EMPATE")) novoStatus = "EMPATE";

            if (mounted) {
              await context.read<UserProvider>().loadUserData(widget.userEmail);
              if (!mounted) return;
            }

            await http.post(
              Uri.parse("${widget.baseUrl}/notificacoes/marcar_como_lido"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"notificacao_id": notif['id']}),
            );

            if (mounted) {
              setState(() {
                _isWaiting = false;
                _status = novoStatus;
                _mensagem = notif['mensagem'] ?? "Batalha finalizada!";
                _rank = (notif['rank_change'] as num).toInt();
                _moedas = (notif['moedas_ganhas'] as num).toInt();
              });
            }
          }
        }
      } catch (e) {
        print("Polling error: $e");
      } finally {
        _polling = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color corStatus = Colors.blue;
    IconData iconeStatus = Icons.hourglass_top;
    String tituloTexto = _status;

    if (_isWaiting) {
      corStatus = Colors.orange;
      tituloTexto = "Placar Salvo!";
      iconeStatus = Icons.cloud_upload;
    } else if (_status == "VITORIA") {
      corStatus = Colors.green;
      iconeStatus = Icons.emoji_events;
    } else if (_status == "DERROTA") {
      corStatus = Colors.red;
      iconeStatus = Icons.mood_bad;
    } else if (_status == "EMPATE") {
      corStatus = Colors.grey;
      iconeStatus = Icons.handshake;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          _isWaiting
              ? const CircularProgressIndicator()
              : Icon(iconeStatus, size: 60, color: corStatus),
          const SizedBox(height: 10),
          Text(
            tituloTexto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: corStatus,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isWaiting
                ? "Aguardando oponente terminar...\nVocê pode esperar aqui ou sair."
                : _mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (!_isWaiting) ...[
            const SizedBox(height: 20),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      "Rank",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _rank >= 0 ? "+$_rank" : "$_rank",
                      style: TextStyle(
                        color: _rank >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      "Moedas",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Color(0xFF69F0AE),
                          size: 18,
                        ),
                        Text(
                          "+$_moedas",
                          style: const TextStyle(
                            color: Color(0xFF69F0AE),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: widget.onClose, // <--- ISSO AGORA FECHA TUDO CERTO
          style: ElevatedButton.styleFrom(
            backgroundColor: corStatus,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isWaiting ? "SAIR AGORA" : "FECHAR",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
