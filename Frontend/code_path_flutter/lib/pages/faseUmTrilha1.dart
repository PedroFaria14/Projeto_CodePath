import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'trilhaUm.dart';

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
  String enunciado = "";
  List<String> alternativas = [];
  int respostaCorreta = 0;
  bool carregando = true;
  int? alternativaSelecionada;
  String idPergunta = "";

  @override
  void initState() {
    super.initState();
    carregarQuestao();
  }

  Future<void> carregarQuestao() async {
    try {
      setState(() => carregando = true);

      final prefs = await SharedPreferences.getInstance();
      final nivel = prefs.getString("userNivel") ?? "iniciante";

      // 🔹 Conversão do nível do app para o do Firebase
      final mapaNiveis = {
        "iniciante": "Facil",
        "intermediario": "Medio",
        "avancado": "Dificil",
      };

      final nivelFirebase = mapaNiveis[nivel.toLowerCase()] ?? "Facil";

      debugPrint(
        "Buscando pergunta para módulo: ${widget.tipoModulo} e nível: $nivelFirebase",
      );

      final response = await http.get(
        Uri.parse(
          "http://10.0.2.2:8000/pergunta/?nivel=$nivelFirebase&tipo=${Uri.encodeComponent(widget.tipoModulo)}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pergunta = data["pergunta"];

        setState(() {
          enunciado = pergunta["pergunta"];
          alternativas = List<String>.from(pergunta["opcoes"]);
          respostaCorreta = alternativas.indexOf(pergunta["resposta_correta"]);
          idPergunta = pergunta["idPergunta"];
          carregando = false;
        });
      } else {
        debugPrint("Erro ao buscar pergunta: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro: $e");
    }
  }

  Future<void> salvarProgresso(int faseAtual) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null) return;

      // 1) Pegar o usuário atual do backend
      final profileResp = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );
      if (profileResp.statusCode != 200) {
        debugPrint(
          "salvarProgresso: falha ao buscar profile ${profileResp.statusCode}",
        );
        return;
      }

      final profileData = jsonDecode(profileResp.body);
      final user = profileData["user"] ?? profileData;

      // 2) Normaliza o campo 'fases' do usuário para um Map<String, List>
      final dynamic rawFases = user["fases"];
      Map<String, dynamic> fasesMap = {};

      if (rawFases == null) {
        // sem dados ainda -> criamos mapa vazio
        fasesMap = {};
      } else if (rawFases is Map) {
        // já está no formato por módulo
        fasesMap = Map<String, dynamic>.from(rawFases);
      } else if (rawFases is List) {
        // formato antigo: lista única -> colocamos ela dentro do módulo atual
        fasesMap = {
          widget.tipoModulo: List<Map<String, dynamic>>.from(rawFases),
        };
      } else {
        // fallback
        fasesMap = {};
      }

      // 3) Pega lista do módulo atual (ou inicializa se vazio)
      List<Map<String, dynamic>> moduleFases = [];
      if (fasesMap.containsKey(widget.tipoModulo) &&
          fasesMap[widget.tipoModulo] is List) {
        moduleFases = List<Map<String, dynamic>>.from(
          fasesMap[widget.tipoModulo],
        );
      }

      // Se moduleFases estiver vazio, inicializa um conjunto padrão (exemplo 5 fases)
      if (moduleFases.isEmpty) {
        moduleFases = List.generate(
          5,
          (i) => {
            "id": i + 1,
            "liberada": i == 0 ? true : false,
            "atual": i == 0 ? true : false,
          },
        );
      }

      // 4) Atualiza o módulo atual *sem tocar nos outros módulos*
      for (var fase in moduleFases) {
        // marca 'atual' somente para a próxima fase (faseAtual + 1)
        fase["atual"] = fase["id"] == (faseAtual + 1);
        // libera a próxima sem travar fases já liberadas
        fase["liberada"] =
            fase["liberada"] == true || fase["id"] == (faseAtual + 1);
      }

      // 5) Atualiza o mapa e prepara payload
      fasesMap[widget.tipoModulo] = moduleFases;

      final payload = {
        "email": email,
        "tipo": widget.tipoModulo, // campo que o backend espera
        "fases": moduleFases,
      };

      debugPrint("salvarProgresso -> payload: ${jsonEncode(payload)}");

      // 6) Chama o endpoint para salvar apenas o módulo atual
      final saveResp = await http.post(
        Uri.parse("http://10.0.2.2:8000/salvar_progresso"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      debugPrint(
        "salvarProgresso -> status: ${saveResp.statusCode}, body: ${saveResp.body}",
      );
    } catch (e) {
      debugPrint("Erro ao salvar progresso: $e");
    }
  }

  void validarResposta() async {
    if (alternativaSelecionada == null) return;

    final correta = alternativaSelecionada == respostaCorreta;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          correta
              ? "✅ Resposta correta! Próxima fase liberada."
              : "❌ Resposta errada, tente novamente.",
        ),
        backgroundColor: correta ? Colors.green : Colors.red,
      ),
    );

    if (correta) {
      await salvarProgresso(widget.faseId);

      Future.delayed(const Duration(seconds: 1), () async {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString("userEmail");

        if (!mounted || email == null) return;

        final response = await http.get(
          Uri.parse("http://10.0.2.2:8000/profile/$email"),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final user = data["user"];

          final Map<String, dynamic> fasesMap = Map<String, dynamic>.from(
            user["fases"] ?? {},
          );
          final List fasesAtualizadas = List<Map<String, dynamic>>.from(
            fasesMap[widget.tipoModulo] ?? [],
          );

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            Image.asset("assets/imagens/gato1.png", height: 80),
            const SizedBox(height: 12),
            Text(
              enunciado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
                    ),
                  ),
                  onPressed: () {
                    setState(() => alternativaSelecionada = index);
                  },
                  child: Text(texto),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: validarResposta,
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
              child: const Text(
                "Enviar",
                style: TextStyle(
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
