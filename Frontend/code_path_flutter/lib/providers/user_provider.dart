// Arquivo: lib/providers/user_provider.dart (COMPLETO E CORRIGIDO)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProvider with ChangeNotifier {
  // Seus dados
  String _nome = "Usuário";
  String _email = "";
  int _rank = 1000;
  int _moedas = 0;
  int _streak = 0;
  bool _isLoading = true;

  String _nivel = "iniciante";
  String _telefone = "-";
  String _dataNascimento = "-";

  // "Getters" (para as telas lerem os dados)
  String get nome => _nome;
  String get email => _email;
  int get rank => _rank;
  int get moedas => _moedas;
  int get streak => _streak;
  bool get isLoading => _isLoading;

  String get nivel => _nivel;
  String get telefone => _telefone;
  String get dataNascimento => _dataNascimento;

  // Função para carregar os dados
  Future<void> loadUserData(String userEmail) async {
    _isLoading = true;
    _email = userEmail;
    // Não notifica os listeners aqui para evitar piscar a tela
    // Só notifica no final

    try {
      final response = await http.get(
        Uri.parse("https://projeto-codepath.onrender.com/profile/$_email"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["user"];
        _nome = data["nome"] ?? "Usuário";
        _rank = data["rank_score"] ?? 1000;
        _moedas = data["moedas"] ?? 0;
        _streak = data["streak"] ?? 0;
        _nivel = data["nivel"] ?? "iniciante";
        _telefone = data["telefone"] ?? "-";
        _dataNascimento = data["data_nascimento"] ?? "-";
      } else {
        // Tratar erro
        _nome = "Erro ao carregar";
      }
    } catch (e) {
      print("Erro no UserProvider: $e");
      _nome = "Erro de conexão";
    }
    _isLoading = false;
    notifyListeners(); // Avisa a UI que terminou de carregar
  }

  // Função para atualizar os valores locais após uma batalha
  void applyBattleRewards(int rankChange, int moedasGanhadas) {
    _rank += rankChange;
    _moedas += moedasGanhadas;

    if (_rank < 0) _rank = 0;

    notifyListeners(); // Avisa a Home e o Perfil para ATUALIZAR AGORA!
  }

  // 🚀 FUNÇÃO NOVA ADICIONADA
  // Chamada pelo PaginaHome se o usuário não estiver logado ou der erro
  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
