import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'tela_configuracao.dart';

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

  Future<void> carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    // 💥 CORREÇÃO 1: Acesso ao email usando a chave consistente 'userEmail'
    final email = prefs.getString("userEmail") ?? "";

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            usuario = data["user"];
            carregando = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (usuario == null) {
      return const Scaffold(body: Center(child: Text("Erro ao carregar perfil")));
    }

    // 🚀 LÓGICA DE CÁLCULO DE PROGRESSO (para o formato MAPA ANINHADO)
    // 1. Define o módulo padrão (use a chave exata do seu FastAPI)
    const String moduloPadrao = "Variáveis"; 
    
    // 2. Extrai o MAPA de fases do usuário
    final Map<String, dynamic> fasesMap = Map<String, dynamic>.from(
        usuario!["fases"] ?? {},
    );
    
    // 3. Pega a lista de fases desse módulo
    final List fasesDoModulo = List<Map<String, dynamic>>.from(
        fasesMap[moduloPadrao] ?? [],
    );
    
    // 4. Faz a contagem (o erro de tipo estava na linha 116)
    final int liberadas = fasesDoModulo.where((f) => f["liberada"] == true).length;
    final int total = fasesDoModulo.length;
    // Se o total for 0 (módulo não existe), previne divisão por zero ou exibição incorreta
    final String progressoFases = total > 0 ? "$liberadas/$total" : "0/0";


    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Perfil"),
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
      // 💥 CORREÇÃO 2: Estrutura do body simplificada após a verificação de loading/erro
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 🔹 Avatar + Nome
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.shade400,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    usuario!["nome"] ?? "Usuário",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    usuario!["email"] ?? "",
                    style: const TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Estatísticas de progresso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCard(
                        "Nível",
                        usuario!["nivel"] ?? "iniciante",
                        Icons.school,
                      ),
                      _statCard(
                        "Streak",
                        "${usuario!["streak"] ?? 0}",
                        Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                      _statCard(
                        "Fases",
                        progressoFases, // Usa a variável calculada
                        Icons.flag,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Informações pessoais
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _info("Idade", "${usuario!["idade"] ?? "-"} anos"),
                        _info("Telefone", "${usuario!["telefone"] ?? "-"}"),
                        _info("Nível atual", usuario!["nivel"] ?? "-"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🔹 Botão sair
                  ElevatedButton.icon(
                    onPressed: logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
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
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon, {
    Color color = Colors.green,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              color: Colors.black87,
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}