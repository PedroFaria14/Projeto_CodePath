// Arquivo: lib/pages/leaderboard_page.dart (ARQUIVO NOVO)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _carregando = true;
  final String _baseUrl = "https://projeto-codepath.onrender.com";

  @override
  void initState() {
    super.initState();
    _carregarLeaderboard();
  }

  Future<void> _carregarLeaderboard() async {
    if (mounted) {
      setState(() => _carregando = true);
    }
    try {
      final response = await http.get(Uri.parse("$_baseUrl/leaderboard"));

      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _leaderboard = List<Map<String, dynamic>>.from(
              data["leaderboard"] ?? [],
            );
          });
        }
      } else {
        throw Exception("Falha ao carregar leaderboard: ${response.body}");
      }
    } catch (e) {
      print("Erro em _carregarLeaderboard: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Não foi possível carregar o placar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  IconData _getMedalIcon(int index) {
    switch (index) {
      case 0:
        return Icons.emoji_events; // Ouro
      case 1:
        return Icons.emoji_events_outlined; // Prata (contorno)
      case 2:
        return Icons.emoji_events_outlined; // Bronze (contorno)
      default:
        return Icons.circle;
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Ouro
      case 1:
        return Colors.grey.shade600; // Prata
      case 2:
        return Colors.brown.shade600; // Bronze
      default:
        return Colors.grey.shade400; // Outros
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Placar de Líderes",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
                  onRefresh: _carregarLeaderboard,
                  child: _leaderboard.isEmpty
                      ? const Center(
                          child: Text(
                            "Ninguém pontuou ainda. Seja o primeiro!",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: _leaderboard.length,
                          itemBuilder: (context, index) {
                            final player = _leaderboard[index];
                            final nome = player["nome"] ?? "Usuário";
                            final score = player["rank_score"] ?? 0;

                            return _buildCardItem(
                              context: context,
                              index: index,
                              nome: nome,
                              score: score,
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }

  // Widget de Card (Estilo 'ModernCard' do perfil)
  Widget _buildCardItem({
    required BuildContext context,
    required int index,
    required String nome,
    required int score,
  }) {
    final medalColor = _getMedalColor(index);
    final medalIcon = _getMedalIcon(index);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
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
        // Ícone de Medalha ou Posição
        leading: (index < 3)
            ? Icon(medalIcon, color: medalColor, size: 40)
            : Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  "${index + 1}.",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

        // Nome do Jogador
        title: Text(
          nome,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2E2E),
            fontSize: 16,
          ),
        ),

        // Pontuação (Rank)
        trailing: Text(
          "$score pts",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
    );
  }
}
