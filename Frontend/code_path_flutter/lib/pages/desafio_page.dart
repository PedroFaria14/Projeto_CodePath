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
import 'resultado_dialog.dart';

class DesafioPage extends StatefulWidget {
  const DesafioPage({super.key});

  @override
  State<DesafioPage> createState() => _DesafioPageState();
}

class _DesafioPageState extends State<DesafioPage> {
  // --- Variáveis de Estado Centralizadas ---
  List<Map<String, dynamic>> quizQuestions = [];
  int currentQuestionIndex = 0;
  int acertos = 0;
  bool carregando = true;
  bool respostaEnviada = false;
  bool _finalizando = false;
  bool _finalizado = false;
  DateTime? _deadline;
  bool _started = false;

  // Variáveis da Fase 1 (Múltipla Escolha)
  int? alternativaSelecionada;

  // Variáveis da Fase 2 (Banco de Palavras)
  List<String> _palavrasSelecionadas = [];
  List<String> _palavrasDisponiveis = [];

  // 🚀 2. NOVAS Variáveis da Fase 3 (Drag & Drop)
  List<String> _blocosParaOrdenar = [];
  List<String> _blocosOrdemCorreta = [];

  Timer? _timer;
  final int _tempoTotalBatalha = 120; // 2 MINUTOS
  int _segundosRestantes = 120;

  String _userEmail = "";
  final String _baseUrl = AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mostrarRegras();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Lógica de Inicialização e Timer ---

  Future<void> _iniciarDesafio() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString("userEmail") ?? "";
    if (!mounted) return;
    if (_userEmail.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/desafio/iniciar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _userEmail}),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          quizQuestions = List<Map<String, dynamic>>.from(
            data['perguntas'] ?? [],
          );
          if (quizQuestions.isEmpty) {
            throw Exception("Nenhuma pergunta recebida do servidor.");
          }
          carregando = false;
        });

        _loadCurrentQuestion();

        // 🚀 MUDANÇA AQUI: Não inicia o timer direto. Mostra as regras antes.
        await _iniciarTimer();
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['detail'] ?? "Erro ao carregar desafio."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print("Erro ao iniciar desafio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro de conexão: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarRegras() {
    showDialog(
      context: context,
      barrierDismissible: false, // O usuário é obrigado a escolher uma opção
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.emoji_events, size: 50, color: Colors.amber),
            SizedBox(height: 10),
            Text(
              "Desafio Semanal",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. AVISO DE TENTATIVAS (NOVO) ---
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1), // Fundo vermelho claro
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Atenção: Você só tem 3 tentativas semanais.",
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Regras Normais ---
            const Text(
              "Prove seu conhecimento!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const ListTile(
              leading: Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text("Acerte pelo menos 6 de 10 questões."),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              leading: Icon(Icons.timer, color: Colors.blue),
              title: Text('Você tem 2 minutos a partir da liberação das questões. O tempo não pausa ao sair.'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              leading: Icon(Icons.star, color: Colors.purple),
              title: Text("Ganhe Moedas e suba no Rank!"),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween, // Separa os botões
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        actions: [
          // --- 2. BOTÃO VOLTAR (NOVO) ---
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Fecha o PopUp
              Navigator.pop(
                context,
              ); // Volta para a tela anterior (sai do desafio)
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: const Text(
              "Voltar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // --- Botão Começar ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3CB371),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Fecha o diálogo
              _iniciarDesafio();
            },
            child: const Text(
              "COMEÇAR",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _iniciarTimer() async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/game/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'attempt_id': quizQuestions.first['attempt_id']}));
      if (!mounted || _finalizando || _finalizado) return;
      if (response.statusCode != 200) {
        throw http.ApiException(http.errorMessage(response, 'Não foi possível iniciar o desafio.'));
      }
      final data = jsonDecode(response.body);
      _deadline = DateTime.parse(data['deadline'] as String);
      setState(() {
        currentQuestionIndex = (data['next_index'] as num).toInt();
        acertos = (data['score'] as num).toInt();
        _segundosRestantes = _deadline!.difference(DateTime.now()).inSeconds.clamp(0, _tempoTotalBatalha);
        _started = true;
      });
      _loadCurrentQuestion();
      if (_finalizando || _finalizado) return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is http.ApiException ? error.message : 'Não foi possível iniciar o desafio.'),
        action: SnackBarAction(label: 'Tentar novamente', onPressed: _iniciarTimer),
      ));
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _deadline!.difference(DateTime.now()).inSeconds.clamp(0, _tempoTotalBatalha);
      if (remaining > 0) {
        if (mounted) {
          setState(() {
            _segundosRestantes = remaining;
          });
        }
      } else {
        timer.cancel();
        _finalizarDesafio(porTempo: true);
      }
    });
  }

  String get _tempoFormatado {
    final int minutes = _segundosRestantes ~/ 60;
    final int seconds = _segundosRestantes % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  // 🚀 3. ATUALIZADO: Prepara o estado para TODAS as fases
  void _loadCurrentQuestion() {
    if (currentQuestionIndex >= quizQuestions.length) {
      _finalizarDesafio();
      return;
    }

    final perguntaAtual = quizQuestions[currentQuestionIndex];
    final int fase = perguntaAtual["fase"] ?? 1;

    setState(() {
      alternativaSelecionada = null; // Reseta Fase 1
      respostaEnviada = false;

      // Prepara a Fase 2 (Banco de Palavras)
      if (fase == 2) {
        _palavrasSelecionadas.clear();
        final List<String> banco = List<String>.from(
          perguntaAtual["palavras_banco"] ?? [],
        );
        banco.shuffle();
        _palavrasDisponiveis = banco;

        // Prepara a Fase 3 (Drag & Drop)
      } else if (fase == 3) {
        _blocosOrdemCorreta = List<String>.from(
          perguntaAtual["partes_codigo"] ?? [],
        );
        _blocosParaOrdenar = List<String>.from(_blocosOrdemCorreta);
        _blocosParaOrdenar.shuffle(); // Embaralha os blocos
      }
    });
  }

  // 🚀 4. ATUALIZADO: Lógica de validação (compara listas na Fase 3)
  Future<void> _handleAnswer(dynamic respostaUsuario, dynamic respostaCorretaEsperada) async {
    if (respostaEnviada || !_started) return;
    setState(() => respostaEnviada = true);
    final question = quizQuestions[currentQuestionIndex];
    final answer = respostaUsuario is int
        ? (question['opcoes'] as List)[respostaUsuario] : respostaUsuario;
    late bool correta;
    try {
      final response = await http.post(Uri.parse('$_baseUrl/game/answer'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'attempt_id': question['attempt_id'], 'index': currentQuestionIndex, 'answer': answer,
        }));
      if (!mounted || _finalizando || _finalizado) return;
      if (response.statusCode != 200) {
        throw http.ApiException(http.errorMessage(response, 'Não foi possível verificar a resposta.'));
      }
      final data = jsonDecode(response.body);
      correta = data['correct'] == true;
      setState(() => acertos = (data['score'] as num).toInt());
    } catch (error) {
      if (!mounted) return;
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
              _finalizarDesafio();
            } else {
              setState(() {
                currentQuestionIndex++;
              });
              _loadCurrentQuestion(); // Carrega a próxima
            }
          },
        );
      },
    );
  }

  // --- Lógica de Finalização e Resultado (Mantida) ---

  Future<void> _finalizarDesafio({bool porTempo = false}) async {
    if (!mounted || _finalizando || _finalizado) return;
    _finalizando = true;
    _timer?.cancel();
    setState(() {
      respostaEnviada = true;
    });

    final pageRoute = ModalRoute.of(context);
    if (pageRoute != null) Navigator.of(context).popUntil((route) => route == pageRoute);
    var loadingOpen = true;

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
      String endpoint = "/desafio/finalizar";
      Map<String, dynamic> body = {'attempt_id': quizQuestions.first['attempt_id']};

      final response = await http.post(
        Uri.parse("$_baseUrl$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      Navigator.pop(context); // Fecha o loading
      loadingOpen = false;

      if (response.statusCode == 200) {
        _finalizado = true;
        final data = jsonDecode(response.body);
        final String statusFinal = data["status_final"] ?? "CONCLUIDO";
        final String mensagem = porTempo
            ? "Tempo esgotado! Você acertou $acertos de ${quizQuestions.length}."
            : data["message"] ?? "Desafio Concluído!";
        final int rankChange = (data["rank_change"] as num? ?? 0).toInt();
        final int moedasGanhas = (data["moedas_ganhas"] as num? ?? 0).toInt();

        await context.read<UserProvider>().loadUserData(_userEmail);
        if (!mounted) return;

        _showResultadoFinalDialog(
          statusFinal,
          mensagem,
          rankChange,
          moedasGanhas,
        );
      } else {
        throw http.ApiException(http.errorMessage(response, 'Não foi possível enviar o resultado.'));
      }
    } catch (e) {
      if (!mounted) return;
      if (loadingOpen) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is http.ApiException ? e.message : 'Não foi possível enviar o resultado.'),
        action: SnackBarAction(label: 'Tentar novamente', onPressed: () => _finalizarDesafio(porTempo: porTempo)),
      ));
    } finally {
      _finalizando = false;
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

  // --- WIDGETS DE RENDERIZAÇÃO CENTRAL E ESPECÍFICOS ---

  Widget _buildQuizBody() {
    if (quizQuestions.isEmpty) return const Expanded(child: SizedBox());
    if (currentQuestionIndex >= quizQuestions.length) {
      return const Expanded(child: Center(child: Text('Todas as respostas foram salvas. Finalizando resultado…')));
    }

    final Map<String, dynamic> perguntaAtual =
        quizQuestions[currentQuestionIndex];
    final int fase = perguntaAtual["fase"] ?? 1;

    Widget questionWidget;

    switch (fase) {
      case 1:
        questionWidget = _buildFase1MultipleChoice(perguntaAtual);
        break;
      case 2:
        questionWidget = _buildFase2WordBank(perguntaAtual);
        break;
      case 3:
        questionWidget = _buildFase3DragAndDrop(perguntaAtual);
        break;
      default:
        questionWidget = const Center(
          child: Text(
            "Erro: Fase desconhecida.",
            style: TextStyle(color: Colors.red),
          ),
        );
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: questionWidget,
      ),
    );
  }

  // ------------------------------------
  // FASE 1: Múltipla Escolha (Sem mudança)
  // ------------------------------------
  Widget _buildFase1MultipleChoice(Map<String, dynamic> pergunta) {
    final List<String> opcoes = List<String>.from(pergunta["opcoes"] ?? []);
    final String enunciado = pergunta["pergunta"] ?? "Erro na pergunta.";

    return Column(
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
        ...opcoes.asMap().entries.map((entry) {
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
                      ? const BorderSide(color: Color(0xFF3CB371), width: 2.5)
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
                      setState(() {
                        alternativaSelecionada = index;
                      });
                    },
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  // -----------------------------------------------------------
  // FASE 2: BANCO DE PALAVRAS (Sem mudança)
  // -----------------------------------------------------------
  Widget _buildFase2WordBank(Map<String, dynamic> pergunta) {
    final String enunciadoFase2 =
        pergunta["texto_pergunta"] ?? "Código com lacuna não encontrado.";
    final String dica = pergunta["dica"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModernCard(
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "FASE 2: Complete o Código",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3CB371),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _buildModernCard(
          Container(
            padding: const EdgeInsets.all(12.0),
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enunciadoFase2.replaceAll("____", " [ ________ ] "),
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (dica.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Dica: $dica",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildAnswerBox(),
        const Divider(height: 30, thickness: 1, color: Colors.white54),
        _buildWordBank(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnswerBox() {
    return Container(
      constraints: const BoxConstraints(minHeight: 55),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white70),
      ),
      child: _palavrasSelecionadas.isEmpty
          ? Text(
              "Toque nas palavras abaixo para construir sua resposta...",
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            )
          : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _palavrasSelecionadas.map((palavra) {
                return Chip(
                  label: Text(
                    palavra,
                    style: GoogleFonts.sourceCodePro(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removerPalavra(palavra),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildWordBank() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      alignment: WrapAlignment.center,
      children: _palavrasDisponiveis.map((palavra) {
        return OutlinedButton(
          onPressed: () => _adicionarPalavra(palavra),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            palavra,
            style: GoogleFonts.sourceCodePro(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _adicionarPalavra(String palavra) {
    if (respostaEnviada) return;
    setState(() {
      _palavrasDisponiveis.remove(palavra);
      _palavrasSelecionadas.add(palavra);
    });
  }

  void _removerPalavra(String palavra) {
    if (respostaEnviada) return;
    setState(() {
      _palavrasSelecionadas.remove(palavra);
      _palavrasDisponiveis.add(palavra);
    });
  }

  // -----------------------------------------------------------
  // 🚀 5. FASE 3: DRAG & DROP (LÓGICA IMPLEMENTADA)
  // -----------------------------------------------------------
  // 🚀 CORREÇÃO: Adicionado ReorderableDragStartListener no ícone
  Widget _buildFase3DragAndDrop(Map<String, dynamic> pergunta) {
    final String titulo = pergunta["titulo"] ?? "Monte o código.";

    return Column(
      children: [
        _buildModernCard(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "FASE 3: Organize o Código",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26),
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _blocosParaOrdenar.length,
            itemBuilder: (context, index) {
              final blocoDeCodigo = _blocosParaOrdenar[index];
              return Card(
                key: ValueKey(blocoDeCodigo),
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    blocoDeCodigo,
                    style: GoogleFonts.sourceCodePro(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  // ⬇️ AQUI ESTÁ O SEGREDO PARA FUNCIONAR O ARRASTAR ⬇️
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_handle,
                      color: Colors.grey,
                      size: 30, // Aumentei um pouco para facilitar o toque
                    ),
                  ),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (respostaEnviada) return;

              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _blocosParaOrdenar.removeAt(oldIndex);
                _blocosParaOrdenar.insert(newIndex, item);
              });
            },
          ),
        ),
      ],
    );
  }

  // 🚀 6. ATUALIZADO: Botão de Envio (agora valida a Fase 3)
  Widget _buildSubmitButton() {
    final Map<String, dynamic>? perguntaAtual = currentQuestionIndex < quizQuestions.length
        ? quizQuestions[currentQuestionIndex]
        : null;
    final int fase = perguntaAtual?["fase"] ?? 1;

    bool canSubmit = false;
    dynamic respostaParaEnviar;
    dynamic corretaEsperada; // Mudou para dynamic

    if (perguntaAtual != null && !respostaEnviada) {
      if (fase == 1) {
        // Fase 1: Múltipla Escolha
        canSubmit = alternativaSelecionada != null;
        respostaParaEnviar = alternativaSelecionada;
        corretaEsperada = perguntaAtual["resposta_correta"] ?? "";
      } else if (fase == 2) {
        // Fase 2: Banco de Palavras
        canSubmit = _palavrasSelecionadas.isNotEmpty;
        respostaParaEnviar = _palavrasSelecionadas.join("");
        corretaEsperada = perguntaAtual["resposta_correta"] ?? "";
      } else if (fase == 3) {
        // Fase 3: Drag & Drop
        canSubmit = true; // Sempre pode enviar a ordem
        respostaParaEnviar = _blocosParaOrdenar;
        corretaEsperada = _blocosOrdemCorreta; // Envia a lista correta
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: ElevatedButton(
        onPressed: canSubmit
            ? () => _handleAnswer(respostaParaEnviar, corretaEsperada)
            : null,
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

  // --- Build Principal ---

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
            const Text(
              "Desafio Semanal",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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

// --- WIDGET DE MODAL SIMPLIFICADO --- (Mantido)
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
