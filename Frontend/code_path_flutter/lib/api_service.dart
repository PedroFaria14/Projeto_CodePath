import 'dart:convert';
import 'package:http/http.dart' as http;

// Modelo de dados para o usuário, que será usado após o login
class User {
  final String nome;
  final String email;
  final int streak;

  User({required this.nome, required this.email, required this.streak});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nome: json['nome'],
      email: json['email'],
      streak: json['streak'],
    );
  }
}

class ApiService {
  // O IP 10.0.2.2 é o endereço padrão do emulador Android para acessar o localhost
  static const String _baseUrl = "http://10.0.2.2:8000";

  // Método para fazer o login do usuário
  static Future<Map<String, dynamic>> loginUser(
    String email,
    String senha,
  ) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "senha": senha}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['user']),
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // teste

  // Método para registrar um novo usuário
  static Future<Map<String, dynamic>> registerUser(
    String nome,
    String email,
    String senha,
  ) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nome": nome, "email": email, "senha": senha}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
