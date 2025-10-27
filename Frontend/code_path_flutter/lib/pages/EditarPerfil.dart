import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditarPerfilPage extends StatefulWidget {
  // Recebe os dados atuais do usuário para preencher os campos
  final Map<String, dynamic> usuario;

  const EditarPerfilPage({super.key, required this.usuario});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  final _formKey = GlobalKey<FormState>(); // Chave para validar o formulário
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // --- 🚀 INÍCIO DA CORREÇÃO ---
    // Pega os dados do widget
    String nome = widget.usuario["nome"] ?? "";
    String email = widget.usuario["email"] ?? "";

    // Se o nome salvo no banco for igual ao email,
    // extrai a primeira parte do email para usar como nome.
    if (nome.contains('@') && nome == email) {
      String nomeDoEmail = nome.split('@')[0];
      if (nomeDoEmail.isNotEmpty) {
        // Capitaliza a primeira letra (ex: "pedro" -> "Pedro")
        nome = nomeDoEmail[0].toUpperCase() + nomeDoEmail.substring(1);
      }
    }
    // --- 🚀 FIM DA CORREÇÃO ---

    // Preenche os controladores com os dados (agora limpos)
    _nomeController = TextEditingController(text: nome);
    _telefoneController = TextEditingController(
      text: widget.usuario["telefone"],
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  // Função para salvar os dados no backend
  Future<void> _salvarPerfil() async {
    // Verifica se os campos (Nome, Telefone) são válidos
    if (!_formKey.currentState!.validate()) {
      return; // Se não for válido, para a execução
    }

    setState(() => _isLoading = true);

    // Pega o email (que não pode ser editado) para usar como chave na API
    final String email = widget.usuario["email"];

    try {
      // Chama o endpoint de atualização no backend
      final response = await http.put(
        Uri.parse(
          "https://projeto-codepath.onrender.com/update_profile/$email",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": _nomeController.text.trim(),
          "telefone": _telefoneController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Sucesso!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil atualizado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        // Volta para a página de perfil e envia 'true' para ela recarregar
        Navigator.pop(context, true);
      } else {
        // Erro
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro: ${data["detail"] ?? "Não foi possível salvar"}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro de conexão: $e"),
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Editar Perfil",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        // Fundo gradiente (mesmo da tela de perfil)
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              // Formulário para validação
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Card flutuante para os campos
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Informações Pessoais",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Campo Nome
                          TextFormField(
                            controller:
                                _nomeController, // Agora usa o nome limpo
                            decoration: _buildInputDecoration("Nome"),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Por favor, insira seu nome";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo Telefone
                          TextFormField(
                            controller: _telefoneController,
                            decoration: _buildInputDecoration("Telefone"),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Por favor, insira seu telefone";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo Email (desabilitado)
                          TextFormField(
                            initialValue:
                                widget.usuario["email"], // Mostra o email
                            decoration: _buildInputDecoration(
                              "Email (não pode ser alterado)",
                            ),
                            enabled: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Botão Salvar
                    ElevatedButton(
                      onPressed: _isLoading ? null : _salvarPerfil,
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
                              "SALVAR ALTERAÇÕES",
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

  // Helper para criar a decoração do Input (estilo do login)
  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F0F0), // Um cinza claro
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}
