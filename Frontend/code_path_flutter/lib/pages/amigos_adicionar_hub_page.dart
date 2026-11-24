// Arquivo: amigos_adicionar_hub_page.dart
// (Design ATUALIZADO para corresponder à sua Imagem 1)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:codepath/core/api_http.dart' as http;
import 'package:codepath/core/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'amigos_busca_page.dart'; // A tela de busca

class AmigosAdicionarHubPage extends StatefulWidget {
  const AmigosAdicionarHubPage({super.key});

  @override
  State<AmigosAdicionarHubPage> createState() => _AmigosAdicionarHubPageState();
}

class _AmigosAdicionarHubPageState extends State<AmigosAdicionarHubPage> {
  List<Map<String, dynamic>> _sugestoes = [];
  bool _carregandoSugestoes = true;
  String _userEmail = "";
  final String _baseUrl = AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _carregarDadosESugestoes();
  }

  Future<void> _carregarDadosESugestoes() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString("userEmail") ?? "";
    if (_userEmail.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _buscarSugestoes();
  }

  Future<void> _buscarSugestoes() async {
    setState(() => _carregandoSugestoes = true);
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/amigos/sugestoes/$_userEmail"),
      );
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sugestoes = List<Map<String, dynamic>>.from(data["sugestoes"] ?? []);
          _carregandoSugestoes = false;
        });
      } else {
        throw Exception("Falha ao carregar sugestões");
      }
    } catch (e) {
      print("Erro em _buscarSugestoes: $e");
      if (mounted) setState(() => _carregandoSugestoes = false);
    }
  }

  Future<void> _enviarPedido(String emailReceptor) async {
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
        setState(() {
          _sugestoes.removeWhere((user) => user['email'] == emailReceptor);
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
      appBar: AppBar(
        title: const Text("Encontre os seus amigos"),
        // Usa o fundo gradiente no AppBar
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFA8E6CF), // Cor verde clara
                Color(0xFF3CB371), // Cor verde principal
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white, // Texto e ícone brancos
        elevation: 0,
      ),
      // Fundo gradiente para o corpo (o mesmo do perfil)
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BOTÃO BUSCAR POR NOME (Estilo Imagem 1) ---
              _buildBotaoOpcao(
                context: context,
                icone: Icons.search,
                texto: "Buscar por nome",
                corBotao: const Color(0xFF3CB371), // Verde
                corIcone: Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AmigosBuscaPage()),
                  );
                },
              ),

              // --- BOTÕES DESABILITADOS (Estilo Imagem 1) ---
              const SizedBox(height: 10),
              _buildBotaoOpcao(
                context: context,
                icone: Icons.contact_page,
                texto: "Escolher nos contatos (Em breve)",
                corBotao: Colors.grey.shade300, // Cinza claro
                corIcone: Colors.grey.shade600,
                onTap: null, // Desabilitado
              ),
              const SizedBox(height: 10),
              _buildBotaoOpcao(
                context: context,
                icone: Icons.link,
                texto: "Link do seu perfil (Em breve)",
                corBotao: Colors.grey.shade300, // Cinza claro
                corIcone: Colors.grey.shade600,
                onTap: null, // Desabilitado
              ),

              const SizedBox(height: 30),

              // --- SEÇÃO SUGESTÕES ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sugestões de amigos",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    TextButton(
                      onPressed: _buscarSugestoes,
                      child: Text(
                        "VER TODOS",
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildListaSugestoes(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para os botões de opção (Estilo Imagem 1)
  Widget _buildBotaoOpcao({
    required BuildContext context,
    required IconData icone,
    required String texto,
    required Color corBotao,
    required Color corIcone,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: corBotao, // Cor do botão
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Row(
          children: [
            Icon(icone, color: corIcone, size: 28),
            const SizedBox(width: 15),
            Text(
              texto,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: onTap != null
                    ? (corIcone == Colors.white ? Colors.white : Colors.black87)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para a lista horizontal de sugestões (Estilo Imagem 1)
  Widget _buildListaSugestoes() {
    if (_carregandoSugestoes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sugestoes.isEmpty) {
      return const Center(child: Text("Nenhuma sugestão encontrada."));
    }

    return SizedBox(
      height: 220, // Altura aumentada
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sugestoes.length,
        itemBuilder: (context, index) {
          final usuario = _sugestoes[index];
          final nome = usuario['nome'] ?? 'Usuário';
          final email = usuario['email'] ?? '';

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(right: 10),
            child: Container(
              width: 170, // Largura aumentada
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green.shade100, // Fundo verde claro
                    child: Text(
                      nome[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ), // Texto verde escuro
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Sugestão",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3CB371), // Verde
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => _enviarPedido(email),
                    child: const Text("SEGUIR", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
