// Arquivo: perfil.dart (ATUALIZADO COM PROVIDER)

import 'dart:convert';
import 'package:codepath/pages/EditarPerfil.dart';
import 'package:flutter/material.dart';
import 'package:codepath/core/api_http.dart' as http;
import 'package:codepath/core/app_config.dart';
import 'package:codepath/core/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'tela_configuracao.dart';
// import 'EditarPerfil.dart'; // Removido, já importado acima

// 🚀 IMPORTS DO PROVIDER
import 'package:provider/provider.dart';
import 'package:codepath/providers/user_provider.dart';

// Imports das novas páginas
import 'amigos_adicionar_hub_page.dart';
import 'convites_page.dart';
import 'amigos_page.dart'; // <--- PÁGINA CENTRAL DE AMIGOS

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  // 🚀 REMOVIDO: Map<String, dynamic>? usuario;
  // 🚀 REMOVIDO: bool carregando = true;

  int _totalConvites = 0;
  int _amigosCount = 0;

  final String _baseUrl = AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    // 🚀 A FUNÇÃO 'carregarUsuario' AGORA SÓ CARREGA OS CONTADORES
    carregarContadores();
  }

  // 🚀 FUNÇÃO 'carregarUsuario' RENOMEADA E SIMPLIFICADA
  Future<void> carregarContadores() async {
    // Reseta os contadores
    setState(() {
      _totalConvites = 0;
      _amigosCount = 0;
    });

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail") ?? "";

    if (email.isEmpty) {
      return;
    }

    // Carrega apenas os dados que NÃO ESTÃO no UserProvider
    _carregarContagemConvites(email);
    _carregarContagemAmigos(email);
  }

  // --- (Função _carregarContagemConvites - sem alterações) ---
  Future<void> _carregarContagemConvites(String email) async {
    int total = 0;
    try {
      final resAmigos = await http.get(
        Uri.parse("$_baseUrl/amigos/pedidos_pendentes/$email"),
      );
      if (mounted && resAmigos.statusCode == 200) {
        final data = jsonDecode(resAmigos.body);
        total += (data["pedidos"] as List).length;
      }
      final resBatalha = await http.get(
        Uri.parse("$_baseUrl/convite/pendentes/$email"),
      );
      if (mounted && resBatalha.statusCode == 200) {
        final data = jsonDecode(resBatalha.body);
        total += (data["convites"] as List).length;
      }
      if (mounted) {
        setState(() {
          _totalConvites = total;
        });
      }
    } catch (e) {
      print("Erro ao carregar contagem de convites: $e");
      if (mounted)
        setState(() {
          _totalConvites = 0;
        });
    }
  }

  // --- (Função _carregarContagemAmigos - sem alterações) ---
  Future<void> _carregarContagemAmigos(String email) async {
    try {
      final res = await http.get(Uri.parse("$_baseUrl/amigos/listar/$email"));
      if (mounted && res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _amigosCount = (data["amigos"] as List).length;
          });
        }
      }
    } catch (e) {
      print("Erro ao contar amigos: $e");
      if (mounted)
        setState(() {
          _amigosCount = 0;
        });
    }
  }

  // --- (Função logout - sem alterações) ---
  void logout() async {
    //... (seu código de logout)
    try {
      await http.post(Uri.parse('${AppConfig.apiBaseUrl}/logout'));
    } catch (_) {
      // A saída local deve funcionar mesmo sem conexão.
    }
    await SessionStore.clear();

    if (!mounted) return;
    context.read<UserProvider>().reset();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 LÊ O PROVIDER E SE REGISTRA PARA MUDANÇAS
    final userProvider = context.watch<UserProvider>();

    // --- (Lógica de Cálculo de Data) ---
    // 🚀 LÊ A DATA DO PROVIDER
    String dataFormatada = "-";
    final String? dataNascDB = userProvider.dataNascimento;
    if (dataNascDB != null && dataNascDB != "-") {
      try {
        final data = DateTime.parse(dataNascDB);
        dataFormatada = DateFormat('dd/MM/yyyy').format(data);
      } catch (e) {
        dataFormatada = dataNascDB;
      }
    }
    // --- Fim da lógica de cálculo ---

    // 🚀 CRIA UM MAPA TEMPORÁRIO PARA PASSAR PARA A 'EditarPerfilPage'
    // (O ideal seria refatorar 'EditarPerfilPage' para também usar o provider)
    final Map<String, dynamic> usuarioMapParaEdicao = {
      "nome": userProvider.nome,
      "email": userProvider.email,
      "data_nascimento": userProvider.dataNascimento,
      "telefone": userProvider.telefone,
      "nivel": userProvider.nivel,
      "rank_score": userProvider.rank,
      "moedas": userProvider.moedas,
      "streak": userProvider.streak,
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Perfil", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // Ícone de Convites (Carta)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.mail_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConvitesPage()),
                  ).then((_) => carregarContadores()); // Recarrega contadores
                },
              ),
              if (_totalConvites > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_totalConvites',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Ícone de Configurações
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        // (Fundo Gradiente)
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
            // 🚀 USA O 'isLoading' DO PROVIDER
            child: userProvider.isLoading
                ? const CircularProgressIndicator(color: Color(0xFF3CB371))
                // 🚀 REMOVE A CHECAGEM 'usuario == null'
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      children: [
                        // (Avatar)
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF3CB371),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // (Nome e Botão Editar)
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  // 🚀 LÊ DO PROVIDER
                                  userProvider.nome,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E2E2E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF2E2E2E),
                                  size: 24,
                                ),
                                onPressed: () async {
                                  final bool? atualizou = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditarPerfilPage(
                                        // 🚀 PASSA O MAPA CRIADO
                                        usuario: usuarioMapParaEdicao,
                                      ),
                                    ),
                                  );
                                  if (atualizou == true && context.mounted) {
                                    // 🚀 AVISA O PROVIDER PARA RECARREGAR
                                    Provider.of<UserProvider>(
                                      context,
                                      listen: false,
                                    ).loadUserData(userProvider.email);
                                    // Recarrega os contadores locais
                                    carregarContadores();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // (Email)
                        Text(
                          // 🚀 LÊ DO PROVIDER
                          userProvider.email,
                          style: const TextStyle(color: Colors.black54),
                        ),

                        // (Botão Adicionar Amigos)
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.person_add_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            "Adicionar Amigos",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3CB371),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AmigosAdicionarHubPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // 🔹 Card de Estatísticas e Informações
                        _buildModernCard(
                          Column(
                            children: [
                              // 👇 ================ STATS ATUALIZADAS ================ 👇
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _statCard(
                                    "Nível",
                                    // 🚀 LÊ DO PROVIDER
                                    userProvider.nivel,
                                    Icons.school,
                                  ),
                                  _statCard(
                                    "Sequência",
                                    // 🚀 LÊ DO PROVIDER
                                    "${userProvider.streak}",
                                    Icons.local_fire_department,
                                    color: Colors.orange,
                                  ),
                                  // --- BOTÃO DE AMIGOS CLICÁVEL (ATUALIZADO) ---
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AmigosPage(),
                                        ),
                                      ).then(
                                        (_) => carregarContadores(),
                                      ); // Recarrega contadores
                                    },
                                    child: _statCard(
                                      "Amigos",
                                      "$_amigosCount", // <-- Usa o contador local
                                      Icons.people_outline,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  // --- FIM DO BOTÃO DE AMIGOS ---
                                ],
                              ),

                              // 👆 =============================================== 👆
                              const SizedBox(height: 20),
                              const Divider(color: Colors.black12, height: 1),
                              const SizedBox(height: 20),

                              // Informações
                              _info(
                                "Nascimento",
                                dataFormatada,
                              ), // <-- Usa a data formatada
                              _info(
                                "Telefone",
                                // 🚀 LÊ DO PROVIDER
                                userProvider.telefone,
                              ),
                              _info(
                                "Nível atual",
                                // 🚀 LÊ DO PROVIDER
                                userProvider.nivel,
                              ),
                              const SizedBox(height: 6),
                              _info(
                                "Pontuação (Rank) 🏆",
                                // 🚀 LÊ DO PROVIDER
                                "${userProvider.rank}",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // (Botão Sair)
                        ElevatedButton.icon(
                          onPressed: logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            "Sair da conta",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares (Sem alterações) ---
  Widget _buildModernCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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

  Widget _statCard(
    String label,
    String value,
    IconData icon, {
    Color color = const Color(0xFF3CB371),
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2E2E2E),
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
