import 'dart:convert';
import 'package:codepath/pages/EditarPerfil.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import para formatar datas
import 'login.dart';
import 'tela_configuracao.dart';
import 'EditarPerfil.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Map<String, dynamic>? usuario;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarUsuario();
  }

  // Função para buscar os dados do usuário no backend
  Future<void> carregarUsuario() async {
    // Garante que o indicador de loading apareça ao recarregar
    setState(() {
      carregando = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail") ?? "";

    // Se não houver email, para a execução
    if (email.isEmpty) {
      if (mounted) {
        setState(() => carregando = false);
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (!mounted) return; // Verifica se o widget ainda está montado

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            usuario = data["user"];
          });
        } else {
          debugPrint("API respondeu com sucesso=false: ${data["message"]}");
        }
      } else {
        debugPrint("Erro HTTP ao carregar perfil: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erro de conexão ao carregar perfil: $e");
    } finally {
      // Garante que o loading saia, mesmo se der erro
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // Função de logout
  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Lógica de Cálculo de Progresso e Formatação de Data ---
    // Inicializa as variáveis com valores padrão
    String progressoFases = "0/0";
    String dataFormatada = "-";

    // Só calcula se o usuário não for nulo
    if (usuario != null) {
      // Lógica de progresso
      const String moduloPadrao = "Variáveis";
      Map<String, dynamic> fasesMap;

      if (usuario!["fases"] is Map) {
        fasesMap = Map<String, dynamic>.from(usuario!["fases"] ?? {});
      } else {
        // Fallback para caso o backend ainda envie uma lista
        fasesMap = {moduloPadrao: List.from(usuario!["fases"] ?? [])};
      }

      final List fasesDoModulo = List<Map<String, dynamic>>.from(
        fasesMap[moduloPadrao] ?? [],
      );

      final int liberadas = fasesDoModulo
          .where((f) => f["liberada"] == true)
          .length;
      final int total = fasesDoModulo.length;
      progressoFases = total > 0 ? "$liberadas/$total" : "0/0";

      // Lógica de formatação de data
      final String? dataNascDB = usuario!["data_nascimento"];
      if (dataNascDB != null) {
        try {
          // Converte "YYYY-MM-DD" para "DD/MM/YYYY"
          final data = DateTime.parse(dataNascDB);
          dataFormatada = DateFormat('dd/MM/yyyy').format(data);
        } catch (e) {
          dataFormatada = dataNascDB; // Mostra a data "crua" se der erro
        }
      }
    }
    // --- Fim da lógica de cálculo ---

    return Scaffold(
      extendBodyBehindAppBar: true, // Permite o gradiente ficar atrás da AppBar
      appBar: AppBar(
        title: const Text("Perfil", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0, // Sem sombra
        foregroundColor: Colors.white, // Cor dos ícones (como a seta "voltar")
        actions: [
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
        // Fundo gradiente (o mesmo do login/cadastro)
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
            // Mostra indicador de loading
            child: carregando
                ? const CircularProgressIndicator(color: Color(0xFF3CB371))
                // Mostra erro se o usuário for nulo após o loading
                : usuario == null
                ? const Text(
                    "Erro ao carregar perfil.\nTente novamente mais tarde.",
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                    textAlign: TextAlign.center,
                  )
                // Mostra o conteúdo da página
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      children: [
                        // 🔹 Avatar
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

                        // 🔹 Nome e Botão de Editar
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // Encolhe a Row
                            children: [
                              Flexible(
                                // Para nomes grandes
                                child: Text(
                                  usuario!["nome"] ?? "Usuário",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E2E2E),
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 🔹 BOTÃO DE EDITAR
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF2E2E2E),
                                  size: 24,
                                ),
                                onPressed: () async {
                                  // 1. Navega para a tela de edição
                                  final bool? atualizou = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditarPerfilPage(usuario: usuario!),
                                    ),
                                  );

                                  // 2. Se a tela de edição retornar 'true',
                                  // recarrega os dados do usuário.
                                  if (atualizou == true && mounted) {
                                    carregarUsuario();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // Email
                        Text(
                          usuario!["email"] ?? "",
                          style: const TextStyle(color: Colors.black54),
                        ),

                        const SizedBox(height: 30),

                        // 🔹 Card de Estatísticas e Informações
                        _buildModernCard(
                          Column(
                            children: [
                              // Estatísticas (Nível, Sequência, Fases)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _statCard(
                                    "Nível",
                                    usuario!["nivel"] ?? "iniciante",
                                    Icons.school,
                                  ),
                                  _statCard(
                                    "Sequência",
                                    "${usuario!["streak"] ?? 0}",
                                    Icons.local_fire_department,
                                    color: Colors.orange,
                                  ),
                                  _statCard(
                                    "Fases",
                                    progressoFases,
                                    Icons.flag,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Colors.black12, height: 1),
                              const SizedBox(height: 20),

                              // Informações ( Nascimento, etc.)
                              _info("Nascimento", dataFormatada),
                              _info(
                                "Telefone",
                                "${usuario!["telefone"] ?? "-"}",
                              ),
                              _info("Nível atual", usuario!["nivel"] ?? "-"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 🔹 Botão Sair
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

  // --- Widgets Auxiliares ---

  // Constrói o card branco flutuante
  Widget _buildModernCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8), // Fundo branco semitransparente
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Sombra suave
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // Constrói cada item de estatística (Nível, Sequência, Fases)
  Widget _statCard(
    String label,
    String value,
    IconData icon, {
    Color color = const Color(0xFF3CB371), // Cor verde padrão
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

  // Constrói cada linha de informação (Idade, Telefone, etc.)
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
