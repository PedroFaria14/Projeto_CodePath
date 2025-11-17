// Arquivo: amigos_busca_page.dart
// (Estilo ATUALIZADO para combinar com o Perfil/Login E COM SUGESTÕES INICIAIS)

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AmigosBuscaPage extends StatefulWidget {
  const AmigosBuscaPage({super.key});

  @override
  State<AmigosBuscaPage> createState() => _AmigosBuscaPageState();
}

class _AmigosBuscaPageState extends State<AmigosBuscaPage> {
  List<Map<String, dynamic>> _listaResultados =
      []; // Agora pode ser busca ou sugestão
  bool _carregando = false;
  String _userEmail = "";
  final TextEditingController _buscaController = TextEditingController();
  bool _mostrandoSugestoesIniciais =
      true; // Novo flag para controlar o que mostrar

  final String _baseUrl = "https://projeto-codepath.onrender.com";

  @override
  void initState() {
    super.initState();
    _carregarEmailUsuario().then((_) {
      if (_userEmail.isNotEmpty) {
        _buscarSugestoesIniciais(); // Busca sugestões ao iniciar a página
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarEmailUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString("userEmail") ?? "";

    if (_userEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro: Usuário não encontrado."),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // Novo método para buscar sugestões ao carregar a página
  Future<void> _buscarSugestoesIniciais() async {
    setState(() {
      _carregando = true;
      _mostrandoSugestoesIniciais = true;
    });
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/amigos/sugestoes/$_userEmail"),
      );
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listaResultados = List<Map<String, dynamic>>.from(
            data["sugestoes"] ?? [],
          );
          _carregando = false;
        });
      } else {
        throw Exception("Falha ao carregar sugestões iniciais");
      }
    } catch (e) {
      print("Erro em _buscarSugestoesIniciais: $e");
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _buscarUsuarios() async {
    final nomeBusca = _buscaController.text.trim();
    if (nomeBusca.isEmpty) {
      // Se a busca estiver vazia, volta a mostrar as sugestões iniciais
      _buscarSugestoesIniciais();
      return;
    }
    if (nomeBusca.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite pelo menos 3 caracteres para buscar."),
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
      _mostrandoSugestoesIniciais =
          false; // Não é mais sugestão inicial, é busca
    });
    try {
      final response = await http.get(
        Uri.parse(
          "$_baseUrl/usuarios/buscar/$nomeBusca?email_atual=$_userEmail",
        ),
      );
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listaResultados = List<Map<String, dynamic>>.from(data ?? []);
          _carregando = false;
        });
      } else {
        throw Exception("Falha ao buscar usuários: ${response.body}");
      }
    } catch (e) {
      print("Erro em _buscarUsuarios: $e");
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao buscar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enviarPedido(String emailReceptor) async {
    if (_userEmail.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/amigos/enviar_pedido"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email_solicitante": _userEmail,
          "email_receptor": emailReceptor,
        }),
      );
      if (mounted && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pedido de amizade enviado!"),
            backgroundColor: Colors.blue,
          ),
        );
        // Remove o usuário da lista local após o pedido
        setState(() {
          _listaResultados.removeWhere(
            (user) => user['email'] == emailReceptor,
          );
        });
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data["detail"] ?? "Falha ao enviar pedido");
      }
    } catch (e) {
      print("Erro em _enviarPedido: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Buscar por Nome",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Alinha o texto do título
              children: [
                // 🔹 Campo de Busca (Estilo Login)
                _buildTextField(
                  controller: _buscaController,
                  hint: "Digite o nome...",
                  icon: Icons.search,
                  onSubmitted: (_) => _buscarUsuarios(),
                  onChanged: (text) {
                    if (text.isEmpty) {
                      _buscarSugestoesIniciais(); // Volta para sugestões se a busca for limpa
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 🔹 Título para a lista
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _mostrandoSugestoesIniciais
                        ? "Sugestões para você"
                        : "Resultados da busca",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 🔹 Resultados / Sugestões
                if (_carregando)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3CB371),
                      ),
                    ),
                  )
                else if (_listaResultados.isEmpty)
                  Center(
                    child: Text(
                      _mostrandoSugestoesIniciais
                          ? "Nenhuma sugestão encontrada no momento."
                          : "Nenhum usuário encontrado com este nome.",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _listaResultados.length,
                      itemBuilder: (context, index) {
                        final usuario = _listaResultados[index];
                        // Card de Resultado (Estilo Perfil)
                        return _buildModernCard(
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF3CB371,
                              ).withOpacity(0.2),
                              child: Text(
                                usuario["nome"]?[0].toUpperCase() ?? "?",
                                style: const TextStyle(
                                  color: Color(0xFF3CB371),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              usuario["nome"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E2E2E),
                              ),
                            ),
                            subtitle: Text(
                              usuario["email"] ?? "",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3CB371),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _enviarPedido(usuario["email"]),
                              child: const Text("Adicionar"),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para o TextField (Copiado do seu login.dart)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Function(String)? onSubmitted,
    Function(String)? onChanged, // Adicionado onChanged
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
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        onSubmitted: onSubmitted,
        onChanged: onChanged, // Atribuído o onChanged
      ),
    );
  }

  // Widget para o Card (Copiado do seu perfil.dart)
  Widget _buildModernCard(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
      child: child,
    );
  }
}
