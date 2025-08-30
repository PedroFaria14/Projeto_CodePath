import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

// Feito com o auxílio do ChatGPT

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  bool isLoading = false;

  Future<void> _cadastrar() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse("http://10.0.2.2:8000/register");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nomeController.text.trim(),
          "email": emailController.text.trim(),
          "senha": senhaController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário cadastrado com sucesso!")),
        );
        Navigator.pop(context); // Volta para a tela de login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Erro no cadastro.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro de conexão: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB2F7C1), Color(0xFFDFF5E1)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset("assets/imagens/gato.png", height: 150, width: 150),
                const SizedBox(height: 30),
                const Text(
                  "Crie sua conta",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: "Nome",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : _cadastrar,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Cadastrar"),
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Já tem uma conta? Entrar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
