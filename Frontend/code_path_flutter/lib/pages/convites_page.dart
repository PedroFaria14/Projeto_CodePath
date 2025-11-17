// Arquivo: convites_page.dart
// (CORRIGIDO: A função _aceitarConviteBatalha foi ativada)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 👇 IMPORTA A TELA DE BATALHA 👇
import 'batalha_page.dart';

class ConvitesPage extends StatefulWidget {
  const ConvitesPage({super.key});

  @override
  State<ConvitesPage> createState() => _ConvitesPageState();
}

class _ConvitesPageState extends State<ConvitesPage> {
  List<Map<String, dynamic>> _pedidosAmizade = [];
  List<Map<String, dynamic>> _convitesBatalha = [];
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro: Usuário não encontrado."),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Tenta carregar as duas listas
    try {
      await _listarPedidosAmizade();
      await _listarConvitesBatalha();
    } catch (e) {
      print("Erro ao carregar convites: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao carregar convites: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _listarPedidosAmizade() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/amigos/pedidos_pendentes/$_userEmail"),
    );
    if (mounted && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _pedidosAmizade = List<Map<String, dynamic>>.from(
          data["pedidos"] ?? [],
        );
      });
    }
  }

  Future<void> _listarConvitesBatalha() async {
    // Busca convites onde o status é 'pendente' OU 'desafiante_jogou'
    // (A correção que fizemos no backend)
    final response = await http.get(
      Uri.parse("$_baseUrl/convite/pendentes/$_userEmail"),
    );
    if (mounted && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _convitesBatalha = List<Map<String, dynamic>>.from(
          data["convites"] ?? [],
        );
      });
    }
  }

  // --- AÇÕES DE CONVITE ---

  Future<void> _aceitarPedidoAmizade(String idPedido) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/amigos/aceitar_pedido"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_pedido": idPedido}),
      );
      if (mounted && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Amizade aceita!"),
            backgroundColor: Colors.green,
          ),
        );
        _carregarDados(); // Recarrega tudo
      } else {
        throw Exception("Falha ao aceitar pedido: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 👇 FUNÇÃO _aceitarConviteBatalha (CORRIGIDA) 👇 ---
  Future<void> _aceitarConviteBatalha(String idConvite) async {
    print("Aceitando batalha $idConvite");
    setState(() => _carregando = true); // Mostra o loading

    // O CÓDIGO AGORA ESTÁ ATIVO (NÃO MAIS COMENTADO)
    try {
      // 1. Chama o backend para pegar as 10 perguntas
      final response = await http.get(
        Uri.parse("$_baseUrl/convite/iniciar/$idConvite/$_userEmail"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> perguntas =
            List<Map<String, dynamic>>.from(data['perguntas'] ?? []);

        if (perguntas.isEmpty) {
          throw Exception("Nenhuma pergunta de batalha foi encontrada.");
        }

        setState(() => _carregando = false); // Para o loading

        // 2. Navega para a tela de batalha
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BatalhaPage(
              perguntas: perguntas,
              tipoBatalha: "CONVITE",
              idConvite: idConvite,
              idBatalhaOponente: null,
              pontuacaoOponente: null,
            ),
          ),
        ).then(
          (_) => _carregarDados(),
        ); // Recarrega a lista de convites ao voltar
      } else {
        throw Exception("Falha ao iniciar convite: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false); // Para o loading em caso de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
    // --- 👆 FIM DA CORREÇÃO 👆 ---
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Caixa de Entrada",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Fundo gradiente
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
                  onRefresh: _carregarDados, // Permite "puxar para atualizar"
                  child: (_pedidosAmizade.isEmpty && _convitesBatalha.isEmpty)
                      ? const Center(
                          child: Text(
                            "Sua caixa de entrada está vazia.",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // --- Seção de Convites de Batalha ---
                            if (_convitesBatalha.isNotEmpty)
                              _buildSecao(
                                "Convites de Batalha",
                                _convitesBatalha.map((convite) {
                                  return _buildCardConvite(
                                    titulo:
                                        convite["email_desafiante"] ??
                                        "Um jogador",
                                    subtitulo: "Te desafiou para uma batalha!",
                                    icone: Icons.bolt,
                                    corIcone: Colors.orange,
                                    textoBotao: "Jogar Agora",
                                    onPressed: () => _aceitarConviteBatalha(
                                      convite["id_convite"],
                                    ),
                                  );
                                }).toList(),
                              ),

                            // --- Seção de Pedidos de Amizade ---
                            if (_pedidosAmizade.isNotEmpty)
                              _buildSecao(
                                "Pedidos de Amizade",
                                _pedidosAmizade.map((pedido) {
                                  return _buildCardConvite(
                                    titulo:
                                        pedido["solicitante_nome"] ?? "Usuário",
                                    subtitulo: "Enviou um pedido de amizade.",
                                    icone: Icons.person_add,
                                    corIcone: Colors.blue,
                                    textoBotao: "Aceitar",
                                    onPressed: () => _aceitarPedidoAmizade(
                                      pedido["id_pedido"],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                ),
        ),
      ),
    );
  }

  // Widget para criar as seções (Batalha / Amigos)
  Widget _buildSecao(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E2E2E),
          ),
        ),
        const SizedBox(height: 10),
        ...children, // Adiciona todos os cards
        const SizedBox(height: 20),
      ],
    );
  }

  // Widget de Card genérico (estilo 'ModernCard' do perfil)
  Widget _buildCardConvite({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color corIcone,
    required String textoBotao,
    required VoidCallback onPressed,
  }) {
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: corIcone.withOpacity(0.2),
          child: Icon(icone, color: corIcone),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E2E2E),
          ),
        ),
        subtitle: Text(
          subtitulo,
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
          onPressed: onPressed,
          child: Text(textoBotao),
        ),
      ),
    );
  }
}
