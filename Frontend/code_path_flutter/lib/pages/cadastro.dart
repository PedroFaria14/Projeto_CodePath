// Arquivo: cadastro.dart (SUBSTITUA O SEU POR ESTE)

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
=======
import 'package:intl/intl.dart'; // Importe o pacote intl
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
import 'login.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
<<<<<<< HEAD
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();
  bool isLoading = false;
  bool obscureSenha = true;
  bool obscureConfirmarSenha = true;

  Future<void> cadastrarUsuario() async {
    if (senhaController.text != confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não coincidem")),
=======
  // Controladores de digitação
  final TextEditingController nomeController = TextEditingController();
  // 🚀 NOVO: Controlador para data de nascimento
  final TextEditingController dataNascimentoController =
      TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  // 🚀 NOVO: Controlador para confirmar senha
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  bool isLoading = false;
  // 🚀 NOVO: Variáveis de estado para visibilidade da senha
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  // 🚀 NOVO: Função para mostrar o DatePicker
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
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
      );
      return;
    }

<<<<<<< HEAD
    setState(() => isLoading = true);

    try {
      final url = Uri.parse("http://localhost:8000/cadastro");
=======
    // 🚀 NOVO: Validação de confirmação de senha
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
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nomeController.text.trim(),
<<<<<<< HEAD
=======
          // 🚀 ALTERADO: Envia 'data_nascimento' em vez de 'idade'
          "data_nascimento": dataNascimentoController.text
              .trim(), // Já está formatada
          "telefone": telefoneController.text.trim(),
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
          "email": emailController.text.trim(),
          "senha": senhaController.text
              .trim(), // Envia apenas a senha principal
        }),
      );

<<<<<<< HEAD
=======
      // Tratamento da resposta (sem alterações na lógica principal)
      if (!mounted) return; // Verifica se o widget ainda está montado

>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
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
<<<<<<< HEAD
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro de conexão: $e")));
=======
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro de conexão: $e")));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
    }
  }

  /*===============================
      INTERFACE MODERNA E ORGÂNICA
  ===============================*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      body: AnimatedContainer(
        duration: const Duration(seconds: 4),
        curve: Curves.easeInOut,
=======
      // Seu fundo gradiente (sem alterações)
      body: Container(
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
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
<<<<<<< HEAD
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
=======
              // Permite rolar se o teclado aparecer
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centraliza verticalmente
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
                children: [
                  // Logo e Título (sem alterações)
                  Image.asset(
                    "assets/imagens/gato.png",
                    height: 120,
                    width: 120,
<<<<<<< HEAD
                  ),
                  const SizedBox(height: 20),

=======
                  ), // Ajustei levemente o tamanho
                  const SizedBox(height: 20),
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
                  const Text(
                    "Crie sua conta",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
<<<<<<< HEAD
                  const SizedBox(height: 40),

                  // 🔹 Container translúcido com campos dentro
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: nomeController,
                              hint: "Nome completo",
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),

                            _buildTextField(
                              controller: emailController,
                              hint: "E-mail",
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 20),

                            _buildPasswordField(
                              controller: senhaController,
                              hint: "Senha",
                              obscure: obscureSenha,
                              onToggleVisibility: () {
                                setState(() {
                                  obscureSenha = !obscureSenha;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            _buildPasswordField(
                              controller: confirmarSenhaController,
                              hint: "Confirmar senha",
                              obscure: obscureConfirmarSenha,
                              onToggleVisibility: () {
                                setState(() {
                                  obscureConfirmarSenha = !obscureConfirmarSenha;
                                });
                              },
                            ),
                            const SizedBox(height: 35),

                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : cadastrarUsuario,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: const Color(0xFF3CB371),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text(
                                        "Cadastrar",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
=======
                  const SizedBox(height: 30),

                  // --- Campos de Texto Atualizados ---

                  // Nome de Usuário
                  TextField(
                    controller: nomeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C2C54),
                      // 🚀 ALTERADO: labelText -> hintText
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
                  const SizedBox(height: 20), // Espaçamento ajustado
                  // 🚀 ALTERADO: Campo Idade para Data de Nascimento
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
                  const SizedBox(height: 20),

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
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

<<<<<<< HEAD
                  const SizedBox(height: 25),
=======
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
                  const SizedBox(height: 20),

                  // Senha
                  TextField(
                    controller: senhaController,
                    style: const TextStyle(color: Colors.white),
                    // 🚀 ALTERADO: obscureText usa a variável de estado
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
                      // 🚀 NOVO: Ícone de visibilidade
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
                  const SizedBox(height: 20),

                  // 🚀 NOVO: Campo Confirmar Senha
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
                  const SizedBox(height: 30),

                  // Botão Confirmar
                  ElevatedButton(
                    onPressed: isLoading ? null : cadastrarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3CB371),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            // Indicador de progresso menor
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
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
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

<<<<<<< HEAD
  // 🔹 Campo de texto normal
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262840),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // 🔹 Campo de senha com ícone de olho 👁️
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262840),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    );
  }
}
=======
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
>>>>>>> 2998262ed1292a427ba31827015bcff5ae48046d
