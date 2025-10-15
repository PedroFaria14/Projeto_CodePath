import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'faseUmTrilha1.dart'; // se quiser manter as fases separadas
import 'package:shared_preferences/shared_preferences.dart';

class PaginaHome extends StatefulWidget {
  const PaginaHome({super.key});

  @override
  State<PaginaHome> createState() => _PaginaHomeState();
}

class _PaginaHomeState extends State<PaginaHome> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userData;
  List<dynamic>? fases;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    try {
      // ⚠️ Aqui use o email do usuário logado (pode ser vindo do login)
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");

      if (email == null) {
        debugPrint("Nenhum email salvo — o usuário precisa logar primeiro.");
        return;
      }

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/profile/$email"),
      );

      if (response.statusCode == 200) {
        setState(() {
          final decoded = jsonDecode(response.body);
          userData = decoded['user'];
          fases = decoded['user']?['fases'];
        });
      } else {
        debugPrint("Erro ao buscar perfil: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro de conexão: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 1) {
      _continuarTrilhaPeloEstado(context);
    } else if (index == 2) {
      // Exemplo: abrir perfil futuramente
    }
  }

  void _continuarTrilhaPeloEstado(BuildContext context) {
    try {
      if (fases == null || fases!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nenhuma fase encontrada no perfil.")),
        );
        return;
      }

      // 🔹 Encontrar a fase atual
      Map<String, dynamic>? faseAtual;

      try {
        faseAtual = fases!.cast<Map<String, dynamic>>().firstWhere(
          (f) => f['atual'] == true,
        );
      } catch (_) {
        // se não houver 'atual', pegar a primeira liberada
        faseAtual = fases!.cast<Map<String, dynamic>>().firstWhere(
          (f) => f['liberada'] == true,
          orElse: () => fases!.first,
        );
      }

      final faseId = faseAtual?['id'] ?? 1;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuestaoPage(faseId: faseId), // ✅ leva pra fase
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao continuar: $e")));
    }
  }

  // 🔹 IMPORTANTE: esse método precisa existir para remover o erro do "build"
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90EE90),
      body: SafeArea(
        child: Center(
          child: Text(
            "Bem-vindo(a), ${userData?['nome'] ?? 'Usuário'}!",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2C2C54),
        unselectedItemColor: Colors.black54,
        backgroundColor: const Color(0xFFE0F8E0),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow_rounded),
            label: "Continuar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
