import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:codepath/core/api_http.dart' as http;
import 'package:codepath/core/app_config.dart';
import 'login.dart'; // Para voltar ao login no final

class RedefinirSenhaPage extends StatefulWidget {
  final String email; // Recebe o email da tela anterior
  const RedefinirSenhaPage({super.key, required this.email});

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final _tokenController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  Future<void> _redefinirSenha() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // A validação de senhas iguais já está no validator do TextFormField

    setState(() => _isLoading = true);

    try {
      // Chama o endpoint do Python para SALVAR a nova senha
      final response = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "token": _tokenController.text.trim(),
          "new_password": _senhaController.text,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200 && jsonDecode(response.body)["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Senha redefinida com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        // Sucesso! Limpa a pilha e volta para a tela de login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              http.errorMessage(response, 'Não foi possível redefinir a senha.'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is http.ApiException ? e.message : 'Não foi possível redefinir. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Criar Nova Senha",
          style: TextStyle(color: Color(0xFF2E2E2E)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2E2E2E), // Cor da seta de voltar
      ),
      body: Container(
        // Fundo gradiente
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Card flutuante
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Insira o código e sua nova senha",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E2E2E),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Campo Código (Token)
                          TextFormField(
                            controller: _tokenController,
                            decoration: _buildInputDecoration(
                              "Código (do email)",
                              Icons.pin_outlined,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().length != 6) {
                                return "Insira o código de 6 dígitos";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Campo Nova Senha
                          TextFormField(
                            controller: _senhaController,
                            obscureText: !_senhaVisivel,
                            decoration: _buildInputDecoration(
                              "Nova Senha",
                              Icons.lock_outline,
                              isSenha: true,
                              visivel: _senhaVisivel,
                              onToggle: () => setState(
                                () => _senhaVisivel = !_senhaVisivel,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Insira uma nova senha";
                              }
                              if (value.length < 8 || utf8.encode(value).length > 72) {
                                return 'Use ao menos 8 caracteres e no máximo 72 bytes.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Campo Confirmar Senha
                          TextFormField(
                            controller: _confirmarSenhaController,
                            obscureText: !_confirmarSenhaVisivel,
                            decoration: _buildInputDecoration(
                              "Confirmar Nova Senha",
                              Icons.lock_outline,
                              isSenha: true,
                              visivel: _confirmarSenhaVisivel,
                              onToggle: () => setState(
                                () => _confirmarSenhaVisivel =
                                    !_confirmarSenhaVisivel,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confirme sua senha";
                              }
                              if (value != _senhaController.text) {
                                return "As senhas não coincidem";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _redefinirSenha,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3CB371),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "SALVAR NOVA SENHA",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Função auxiliar para criar a decoração dos campos de texto
  InputDecoration _buildInputDecoration(
    String hintText,
    IconData icon, {
    bool isSenha = false,
    bool visivel = false,
    VoidCallback? onToggle,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F0F0), // Fundo claro para os campos
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // Sem borda visível
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      suffixIcon: isSenha
          ? IconButton(
              icon: Icon(
                visivel ? Icons.visibility : Icons.visibility_off,
                color: Colors.black54,
              ),
              onPressed: onToggle, // Chama a função para alternar visibilidade
            )
          : null, // Não mostra ícone se não for senha
    );
  }
}
