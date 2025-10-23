// Arquivo: cadastro.dart (SUBSTITUA O SEU POR ESTE)

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importe o pacote intl
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  // Controladores de digitação
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController dataNascimentoController =
      TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  bool isLoading = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  // Função para mostrar o DatePicker
  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // Sugere 18 anos atrás
      firstDate: DateTime(1920), // Data mínima
      lastDate: DateTime.now(), // Data máxima (hoje)
      locale: const Locale(
        'pt',
        'BR',
      ), // Opcional: para calendário em português
    );

    if (dataSelecionada != null) {
      // Formata a data para YYYY-MM-DD
      final String dataFormatada = DateFormat(
        'yyyy-MM-dd',
      ).format(dataSelecionada);
      setState(() {
        dataNascimentoController.text = dataFormatada;
      });
    }
  }

  Future<void> cadastrarUsuario() async {
    // --- Validações no Frontend ---
    if (nomeController.text.trim().isEmpty ||
        dataNascimentoController.text.trim().isEmpty ||
        telefoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        senhaController.text.trim().isEmpty ||
        confirmarSenhaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Por favor, preencha todos os campos."),
        ),
      );
      return;
    }

    if (senhaController.text != confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ As senhas não coincidem!")),
      );
      return; // Impede o envio para a API
    }
    // --- Fim das Validações ---

    setState(() => isLoading = true);

    try {
      final url = Uri.parse("http://10.0.2.2:8000/register"); // Seu endpoint
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nomeController.text.trim(),
          "data_nascimento": dataNascimentoController.text
              .trim(), // Já está formatada
          "telefone": telefoneController.text.trim(),
          "email": emailController.text.trim(),
          "senha": senhaController.text
              .trim(), // Envia apenas a senha principal
        }),
      );

      // Tratamento da resposta (sem alterações na lógica principal)
      if (!mounted) return; // Verifica se o widget ainda está montado

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userEmail", emailController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!")),
        );
        // Navega para Login substituindo a tela atual
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaginaHome()),
        );
      } else {
        // Tenta pegar a mensagem de detalhe do HTTPException do FastAPI
        String errorMessage =
            data["detail"] ??
            data["message"] ??
            "Erro desconhecido ao cadastrar";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ $errorMessage")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro de conexão: $e")));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /*===============================
      INTERFACE MODERNA E ORGÂNICA
  ===============================*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Center(
            child: SingleChildScrollView(
              // 🚀 NOVO: Adiciona padding nas laterais do formulário
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centraliza verticalmente
                children: [
                  // Logo e Título (sem alterações)
                  Image.asset(
                    "assets/imagens/gato.png",
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Crie sua conta",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  // 🚀 ALTERADO: Espaçamento
                  const SizedBox(height: 24),

                  // --- Campos de Texto Atualizados ---

                  // Nome de Usuário
                  TextField(
                    controller: nomeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C54),
                      hintText: "Nome de usuário",
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ), // Ajuste padding
                    ),
                  ),
                  // 🚀 ALTERADO: Espaçamento
                  const SizedBox(height: 16),

                  // Data de Nascimento
                  TextField(
                    controller: dataNascimentoController,
                    style: const TextStyle(color: Colors.white),
                    readOnly: true, // Impede digitação direta
                    onTap: () => _selecionarData(context), // Chama o DatePicker
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C54),
                      hintText: "Data de Nascimento (AAAA-MM-DD)",
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      // Adiciona ícone de calendário
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  // 🚀 ALTERADO: Espaçamento
                  const SizedBox(height: 16),

                  // Telefone
                  TextField(
                    controller: telefoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType:
                        TextInputType.phone, // Define teclado numérico
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C54),
                      hintText: "Telefone",
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                    ),
                  ),
                  // 🚀 ALTERADO: Espaçamento
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C54),
                      hintText: "Email",
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                    ),
                  ),
                  // 🚀 ALTERADO: Espaçamento
                  const SizedBox(height: 16),

                  // Senha
                  TextField(
                    controller: senhaController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: !_senhaVisivel,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C54),
                      hintText: "Senha",
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaVisivel
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _senhaVisivel = !_senhaVisivel;
                          });
                        },
                      ),
                    ),
                  ),
                  // 🚀 ALTERADO: Espaçamento
                  const SizedBox(height: 16),

                  // Confirmar Senha
                  TextField(
                    controller: confirmarSenhaController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: !_confirmarSenhaVisivel,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C54),
                      hintText: "Confirmar Senha",
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmarSenhaVisivel
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                          });
                        },
                      ),
                    ),
                  ),
                  // 🚀 ALTERADO: Espaçamento
                  const SizedBox(height: 24),

                  // Botão Confirmar
                  ElevatedButton(
                    onPressed: isLoading ? null : cadastrarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3CB371),
                      // 🚀 ALTERADO: Altura do botão
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "CONFIRMAR",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ), // Texto em branco
                  ),
                  const SizedBox(height: 15),

                  // Link para Login (sem alterações)
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                    ),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Já tem uma conta? ',
                        style: TextStyle(color: Colors.black87, fontSize: 15),
                        children: [
                          TextSpan(
                            text: 'Faça login',
                            style: TextStyle(
                              color: Color(0xFF3CB371),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Espaço extra no final
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Limpa os controladores quando o widget é descartado
  @override
  void dispose() {
    nomeController.dispose();
    dataNascimentoController.dispose();
    telefoneController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }
}
