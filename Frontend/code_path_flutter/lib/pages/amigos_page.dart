// Arquivo: amigos_page.dart
// (CORRIGIDO: A aba "Pedidos" agora busca os convites de batalha corretamente)

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'amigos_busca_page.dart';
import 'batalha_page.dart';

class AmigosPage extends StatefulWidget {
  const AmigosPage({super.key});

  @override
  State<AmigosPage> createState() => _AmigosPageState();
}

class _AmigosPageState extends State<AmigosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _listaAmigos = [];
  List<Map<String, dynamic>> _listaPedidos = [];
  List<Map<String, dynamic>> _listaBusca = [];
  List<Map<String, dynamic>> _convitesBatalha = [];

  bool _carregandoAmigos = true;
  bool _carregandoPedidos = true;
  bool _carregandoBusca = false;

  String _userEmail = "";
  String _userNivel = "iniciante";
  final TextEditingController _buscaController = TextEditingController();

  final String _baseUrl = "https://projeto-codepath.onrender.com";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString("userEmail") ?? "";
    _userNivel = prefs.getString("userNivel") ?? "iniciante";

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
      return;
    }
    _listarAmigos();
    _listarPedidosPendentes();
  }

  Future<void> _listarAmigos() async {
    setState(() => _carregandoAmigos = true);
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/amigos/listar/$_userEmail"),
      );
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listaAmigos = List<Map<String, dynamic>>.from(data["amigos"] ?? []);
          _carregandoAmigos = false;
        });
      } else {
        throw Exception("Falha ao carregar amigos: ${response.body}");
      }
    } catch (e) {
      print("Erro em _listarAmigos: $e");
      if (mounted) setState(() => _carregandoAmigos = false);
    }
  }

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
        _listarAmigos();
      } else {
        throw Exception("Falha ao remover amigo: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _desafiarAmigo(String emailAmigo, String nomeAmigo) async {
    print("Desafiando $nomeAmigo ($emailAmigo)");
    setState(() => _carregandoAmigos = true);

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

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception("Falha ao criar convite: ${response.body}");
      }

      final data = jsonDecode(response.body);
      final idConvite = data["id_convite"];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Convite enviado! Jogue sua rodada..."),
          backgroundColor: Colors.green,
        ),
      );

      final responseIniciar = await http.get(
        Uri.parse("$_baseUrl/convite/iniciar/$idConvite/$_userEmail"),
      );

      if (!mounted) return;

      if (responseIniciar.statusCode != 200) {
        throw Exception(
          "Falha ao iniciar seu convite: ${responseIniciar.body}",
        );
      }

      final dataIniciar = jsonDecode(responseIniciar.body);
      final List<Map<String, dynamic>> perguntas =
          List<Map<String, dynamic>>.from(dataIniciar['perguntas'] ?? []);

      if (perguntas.isEmpty) {
        throw Exception("Erro: Nenhuma pergunta de batalha foi encontrada.");
      }

      setState(() => _carregandoAmigos = false);

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
      );
    } catch (e) {
      print("Erro em _desafiarAmigo: $e");
      if (mounted) {
        setState(() => _carregandoAmigos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao desafiar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _buscarUsuarios() async {
    final nomeBusca = _buscaController.text;
    if (nomeBusca.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite pelo menos 3 caracteres para buscar."),
        ),
      );
      return;
    }
    setState(() => _carregandoBusca = true);
    try {
      final response = await http.get(
        Uri.parse(
          "$_baseUrl/usuarios/buscar/$nomeBusca?email_atual=$_userEmail",
        ),
      );
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listaBusca = List<Map<String, dynamic>>.from(data ?? []);
          _carregandoBusca = false;
        });
      } else {
        throw Exception("Falha ao buscar usuários: ${response.body}");
      }
    } catch (e) {
      print("Erro em _buscarUsuarios: $e");
      if (mounted) setState(() => _carregandoBusca = false);
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
          _listaBusca.removeWhere((user) => user['email'] == emailReceptor);
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

  // --- 👇 FUNÇÃO _listarPedidosPendentes ATUALIZADA 👇 ---
  Future<void> _listarPedidosPendentes() async {
    setState(() => _carregandoPedidos = true);
    try {
      // 1. Pega Pedidos de Amizade (status == "pendente")
      final responseAmigos = await http.get(
        Uri.parse("$_baseUrl/amigos/pedidos_pendentes/$_userEmail"),
      );
      if (mounted && responseAmigos.statusCode == 200) {
        final data = jsonDecode(responseAmigos.body);
        setState(() {
          _listaPedidos = List<Map<String, dynamic>>.from(
            data["pedidos"] ?? [],
          );
        });
      }

      // 2. Pega Convites de Batalha (status == "pendente" OU "desafiante_jogou")
      // (Esta é a função que usa o endpoint CORRIGIDO do backend)
      final responseBatalha = await http.get(
        Uri.parse("$_baseUrl/convite/pendentes/$_userEmail"),
      );
      if (mounted && responseBatalha.statusCode == 200) {
        final data = jsonDecode(responseBatalha.body);
        setState(() {
          _convitesBatalha = List<Map<String, dynamic>>.from(
            data["convites"] ?? [],
          );
        });
      }
    } catch (e) {
      print("Erro em _listarPedidosPendentes: $e");
    } finally {
      if (mounted) {
        setState(() => _carregandoPedidos = false);
      }
    }
  }
  // --- 👆 FIM DA ATUALIZAÇÃO 👆 ---

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
        _listarAmigos();
        _listarPedidosPendentes();
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

  // --- 👇 FUNÇÃO _aceitarConviteBatalha ATUALIZADA 👇 ---
  Future<void> _aceitarConviteBatalha(String idConvite) async {
    print("Aceitando batalha $idConvite");
    setState(() => _carregandoPedidos = true);

    try {
      // 1. Pega as perguntas para o Jogador B
      final response = await http.get(
        Uri.parse("$_baseUrl/convite/iniciar/$idConvite/$_userEmail"),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception("Falha ao iniciar convite: ${response.body}");
      }

      final data = jsonDecode(response.body);
      final List<Map<String, dynamic>> perguntas =
          List<Map<String, dynamic>>.from(data['perguntas'] ?? []);

      if (perguntas.isEmpty) {
        throw Exception("Erro: Nenhuma pergunta de batalha foi encontrada.");
      }

      setState(() => _carregandoPedidos = false);

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
      ).then((_) => _carregarDadosUsuario()); // Recarrega tudo ao voltar
    } catch (e) {
      if (mounted) {
        setState(() => _carregandoPedidos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- 👆 FIM DA ATUALIZAÇÃO 👆 ---

  @override
  Widget build(BuildContext context) {
    // Cor azul para os ícones das abas
    final Color corPrincipal = Colors.blue.shade700;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Central de Amigos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,

        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicator: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white, width: 3.0)),
          ),
          tabs: [
            Tab(
              icon: Icon(Icons.people),
              text: "Amigos (${_listaAmigos.length})",
            ),
            Tab(icon: Icon(Icons.person_add), text: "Adicionar"),
            Tab(
              icon: Icon(Icons.mail),
              text:
                  "Pedidos (${_listaPedidos.length + _convitesBatalha.length})",
            ),
          ],
        ),
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
          child: TabBarView(
            controller: _tabController,
            children: [
              // --- ABA 1: MEUS AMIGOS ---
              _buildAbaAmigos(corPrincipal),
              // --- ABA 2: ADICIONAR AMIGOS ---
              _buildAbaAdicionar(),
              // --- ABA 3: PEDIDOS PENDENTES ---
              _buildAbaPedidos(corPrincipal),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: ABA 1 (LISTA DE AMIGOS) ---
  Widget _buildAbaAmigos(Color cor) {
    if (_carregandoAmigos) {
      return Center(child: CircularProgressIndicator(color: cor));
    }
    if (_listaAmigos.isEmpty) {
      return const Center(
        child: Text(
          "Você ainda não tem amigos.\nAdicione na próxima aba!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _listarAmigos,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _listaAmigos.length,
        itemBuilder: (context, index) {
          final amigo = _listaAmigos[index];
          final nome = amigo["nome"] ?? "Nome não encontrado";
          final email = amigo["email"] ?? "Email não encontrado";

          return _buildModernCard(
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cor.withOpacity(0.2),
                child: Text(
                  nome[0].toUpperCase(),
                  style: TextStyle(color: cor, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                nome,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
              subtitle: Text(
                email,
                style: const TextStyle(color: Colors.black54),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.bolt,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                    tooltip: "Desafiar",
                    onPressed: () => _desafiarAmigo(email, nome),
                  ),
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
        },
      ),
    );
  }

  // --- WIDGET: ABA 2 (ADICIONAR AMIGOS) ---
  Widget _buildAbaAdicionar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Campo de Busca (Estilo Login)
          _buildTextField(
            controller: _buscaController,
            hint: "Buscar por nome...",
            icon: Icons.search,
            onSubmitted: (_) => _buscarUsuarios(),
          ),
          const SizedBox(height: 10),
          _buildBotaoOpcao(
            // Botão de busca verde
            texto: "Buscar",
            icone: Icons.send,
            cor: const Color(0xFF3CB371),
            onTap: _buscarUsuarios,
          ),

          const SizedBox(height: 20),

          // Resultados da Busca
          if (_carregandoBusca)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF3CB371)),
            )
          else if (_listaBusca.isEmpty && _buscaController.text.isNotEmpty)
            const Text(
              "Nenhum usuário encontrado.",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _listaBusca.length,
              itemBuilder: (context, index) {
                final usuario = _listaBusca[index];
                return _buildModernCard(
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: Text(usuario["nome"]?[0].toUpperCase() ?? "?"),
                    ),
                    title: Text(usuario["nome"] ?? ""),
                    subtitle: Text(usuario["email"] ?? ""),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _enviarPedido(usuario["email"]),
                      child: const Text("Adicionar"),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- WIDGET: ABA 3 (PEDIDOS PENDENTES) ---
  Widget _buildAbaPedidos(Color cor) {
    if (_carregandoPedidos) {
      return Center(child: CircularProgressIndicator(color: cor));
    }
    if (_listaPedidos.isEmpty && _convitesBatalha.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum pedido pendente.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _listarPedidosPendentes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção Convites de Batalha
          if (_convitesBatalha.isNotEmpty)
            _buildSecao(
              "Convites de Batalha",
              _convitesBatalha.map((convite) {
                return _buildModernCard(
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      child: Icon(Icons.bolt, color: Colors.orange.shade700),
                    ),
                    title: Text(
                      convite["email_desafiante"] ?? "Um jogador",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Te desafiou para uma batalha!"),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3CB371),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _aceitarConviteBatalha(convite["id_convite"]),
                      child: const Text("Jogar"),
                    ),
                  ),
                );
              }).toList(),
            ),

          // Seção Pedidos de Amizade
          if (_listaPedidos.isNotEmpty)
            _buildSecao(
              "Pedidos de Amizade",
              _listaPedidos.map((pedido) {
                return _buildModernCard(
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      child: Icon(
                        Icons.person_add,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    title: Text(
                      pedido["solicitante_nome"] ?? "Usuário",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Enviou um pedido de amizade."),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _aceitarPedidoAmizade(pedido["id_pedido"]),
                      child: const Text("Aceitar"),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES DE DESIGN ---

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Function(String)? onSubmitted,
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }

  Widget _buildBotaoOpcao({
    required String texto,
    required IconData icone,
    required Color cor,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icone, color: Colors.white, size: 24),
      label: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: cor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildSecao(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }
}
