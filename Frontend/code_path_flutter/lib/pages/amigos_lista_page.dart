// Arquivo: amigos_lista_page.dart
// (Design ATUALIZADO para corresponder à sua Imagem 2)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'amigos_adicionar_hub_page.dart'; // A tela de adicionar (Imagem 1)

// (TODO: Importar a futura tela de batalha)
// import 'batalha_page.dart';

class AmigosListaPage extends StatefulWidget {
  const AmigosListaPage({super.key});

  @override
  State<AmigosListaPage> createState() => _AmigosListaPageState();
}

class _AmigosListaPageState extends State<AmigosListaPage> {
  List<Map<String, dynamic>> _listaAmigos = [];
  bool _carregando = true;

  String _userEmail = "";
  String _userNivel = "iniciante";
  final String _baseUrl = "https://projeto-codepath.onrender.com";

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString("userEmail") ?? "";
    _userNivel = prefs.getString("userNivel") ?? "iniciante";

    if (_userEmail.isEmpty) {
      if (mounted) {
        setState(() => _carregando = false);
        Navigator.of(context).pop(); // Volta se não estiver logado
      }
      return;
    }

    // Unica função é listar os amigos
    await _listarAmigos();

    if (mounted) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _listarAmigos() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/amigos/listar/$_userEmail"),
      );
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listaAmigos = List<Map<String, dynamic>>.from(data["amigos"] ?? []);
        });
      } else {
        throw Exception("Falha ao carregar amigos: ${response.body}");
      }
    } catch (e) {
      print("Erro em _listarAmigos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao carregar amigos: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- AÇÕES ---

  Future<void> _removerAmigo(String emailAmigo, String nomeAmigo) async {
    final bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover Amigo"),
        content: Text("Você tem certeza que quer remover $nomeAmigo?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text("Remover", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/amigos/remover"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email_usuario_atual": _userEmail,
          "email_amigo_para_remover": emailAmigo,
        }),
      );
      if (mounted && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Amigo removido."),
            backgroundColor: Colors.grey,
          ),
        );
        _listarAmigos(); // Atualiza a lista
      } else {
        throw Exception("Falha ao remover amigo: ${response.body}");
      }
    } catch (e) {
      print("Erro em _removerAmigo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _desafiarAmigo(String emailAmigo, String nomeAmigo) async {
    print("Desafiando $nomeAmigo ($emailAmigo)");

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/convite/criar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email_desafiante": _userEmail,
          "email_desafiado": emailAmigo,
          "nivel": _userNivel,
        }),
      );

      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final idConvite = data["id_convite"];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Convite enviado para $nomeAmigo! Jogue sua rodada."),
            backgroundColor: Colors.green,
          ),
        );

        // TODO: Navegar para BatalhaPage para o DESAFIANTE jogar
        print(
          "TODO: Navegar para BatalhaPage (Convite) com id_convite: $idConvite",
        );
      } else {
        throw Exception("Falha ao criar convite: ${response.body}");
      }
    } catch (e) {
      print("Erro em _desafiarAmigo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao desafiar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Função para navegar para a página de adicionar amigos
  void _navegarParaAdicionarAmigos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AmigosAdicionarHubPage()),
    ).then((_) => _carregarDados()); // Recarrega a lista ao voltar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Meus Amigos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),

      // Botão Flutuante para Adicionar (como na imagem)
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaAdicionarAmigos,
        backgroundColor: const Color(0xFF3CB371), // Verde
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Fundo gradiente (igual ao perfil)
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
          child: _carregando
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3CB371)),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: (_listaAmigos.isEmpty)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "Você ainda não tem amigos.\nClique no botão '+' para adicionar.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: _listaAmigos.length,
                          itemBuilder: (context, index) {
                            final amigo = _listaAmigos[index];
                            return _buildCardAmigo(amigo);
                          },
                        ),
                ),
        ),
      ),
    );
  }

  // Widget para o Card de Amigo (Estilo 'ModernCard' da imagem)
  Widget _buildCardAmigo(Map<String, dynamic> amigo) {
    final nome = amigo["nome"] ?? "Nome não encontrado";
    final email = amigo["email"] ?? "Email não encontrado";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Card branco
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            nome[0].toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          nome,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E2E2E),
          ),
        ),
        subtitle: Text(email, style: const TextStyle(color: Colors.black54)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Desafiar (Ícone da imagem)
            IconButton(
              icon: Icon(Icons.bolt, color: Colors.orange.shade700, size: 28),
              tooltip: "Desafiar",
              onPressed: () => _desafiarAmigo(email, nome),
            ),
            // Botão Remover (Ícone da imagem)
            IconButton(
              icon: Icon(
                Icons.person_remove_outlined,
                color: Colors.grey.shade600,
                size: 26,
              ),
              tooltip: "Remover Amigo",
              onPressed: () => _removerAmigo(email, nome),
            ),
          ],
        ),
      ),
    );
  }
}
