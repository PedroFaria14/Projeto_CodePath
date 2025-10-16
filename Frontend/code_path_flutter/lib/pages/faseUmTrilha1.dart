import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'trilhaUm.dart';

class QuestaoPage extends StatefulWidget {
  final int faseId;

  const QuestaoPage({super.key, required this.faseId});

  @override
  State<QuestaoPage> createState() => _QuestaoPageState();
}

class _QuestaoPageState extends State<QuestaoPage> {
  // 🔹 Função para salvar o progresso no backend e liberar a próxima fase
  Future<void> salvarProgresso(int faseAtual) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      if (email == null) return;

      // 1️⃣ Buscar o progresso atual do usuário
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final user = data["user"];
      final fases = List<Map<String, dynamic>>.from(user["fases"]);

      // 2️⃣ Atualizar a fase atual e liberar a próxima
      for (var fase in fases) {
        if (fase["id"] == faseAtual) {
          fase["atual"] = false;
        } else if (fase["id"] == faseAtual + 1) {
          fase["liberada"] = true;
          fase["atual"] = true;
        }
      }

      // 3️⃣ Enviar o progresso atualizado pro backend
      await http.post(
        Uri.parse("http://10.0.2.2:8000/salvar_progresso"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "fases": fases}),
      );
    } catch (e) {
      debugPrint("Erro ao salvar progresso: $e");
    }
  }

  String enunciado = "";
  String codigo = "";
  List<String> alternativas = [];
  int respostaCorreta = 0;
  bool carregando = true;
  int? alternativaSelecionada;

  @override
  void initState() {
    super.initState();
    carregarQuestao();
  }

  // 🔹 Simulação de banco de dados local
  Future<void> carregarQuestao() async {
    await Future.delayed(const Duration(milliseconds: 300)); // simula atraso

    final questoes = {
      1: {
        "enunciado": "Qual será a saída do código abaixo?",
        "codigo": "for i in range(3):\n    print(i)",
        "alternativas": ["0 1 2", "1 2 3", "Erro", "Nenhuma das anteriores"],
        "respostaCorreta": 0,
      },
      2: {
        "enunciado": "Qual estrutura repete até uma condição ser falsa?",
        "codigo": "while x < 5:\n    print(x)",
        "alternativas": ["if", "while", "for", "switch"],
        "respostaCorreta": 1,
      },
    };

    final dados = questoes[widget.faseId];

    if (dados != null) {
      setState(() {
        enunciado = dados["enunciado"] as String;
        codigo = dados["codigo"] as String;
        alternativas = List<String>.from(dados["alternativas"] as List);
        respostaCorreta = dados["respostaCorreta"] as int;
        carregando = false;
      });
    }
  }

  void validarResposta() {
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
      salvarProgresso(widget.faseId);

      // Pequeno delay para mostrar o snackbar antes de voltar pra trilha
      Future.delayed(const Duration(seconds: 1), () async {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString("userEmail");

        if (!mounted) return;

        // 🔹 Recarrega dados atualizados do backend
        final response = await http.get(
          Uri.parse("http://10.0.2.2:8000/profile/$email"),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final fasesAtualizadas = List<Map<String, dynamic>>.from(
            data["user"]["fases"],
          );

          // Substitui a tela atual pela trilha, mostrando o progresso atualizado
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TrilhaUm(
                tipoModulo: fasesAtualizadas.first["tipo"] ?? "Desconhecido",
                fases: fasesAtualizadas,
              ),
            ),
          );
        } else {
          Navigator.pop(context); // fallback em caso de erro
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
          "Fase ${widget.faseId}",
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

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                codigo,
                style: const TextStyle(fontFamily: "monospace", fontSize: 16),
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
