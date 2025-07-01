import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // A URL base do seu backend FastAPI.
  // Se estiver a correr no emulador Android, use 10.0.2.2 para aceder ao localhost da sua máquina.
  // Se estiver a correr no iOS Simulator, use localhost.
  // Se estiver a correr no Flutter Web, use localhost ou o IP da sua máquina.
  final String baseUrl =
      "http://10.0.2.2:8000/api"; // Exemplo para emulador Android

  // Método para registar um novo utilizador
  Future<Map<String, dynamic>> registerUser(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha no registo');
    }
  }

  // Método para fazer login
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha no login');
    }
  }

  // Método para obter os dados do utilizador logado
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Envia o token de autenticação
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['detail'] ?? 'Falha ao carregar perfil do utilizador');
    }
  }

  // Método para obter as lições
  Future<List<dynamic>> getLessons() async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/users/lessons'), // A rota de lições não precisa de autenticação neste exemplo
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao carregar lições');
    }
  }

  // Método para marcar uma lição como completa
  Future<Map<String, dynamic>> completeLesson(
      String userId, String lessonId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/complete_lesson?lesson_id=$lessonId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Envia o token de autenticação
      },
      body: jsonEncode({}), // O corpo pode ser vazio ou conter dados adicionais
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao completar lição');
    }
  }

  // Método para obter dicas da API Gemini (pode ser um proxy via FastAPI ou direto)
  Future<String> getGeminiHint(String prompt) async {
    // Se quiser que o FastAPI seja um proxy para o Gemini:
    // final response = await http.post(
    //   Uri.parse('$baseUrl/gemini/hint'), // Exemplo de endpoint no FastAPI
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'prompt': prompt}),
    // );

    // Se for chamar o Gemini diretamente do Flutter (como no exemplo React anterior):
    const String apiKey =
        ""; // A chave será fornecida pelo ambiente, não a insira aqui
    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['candidates'] != null &&
          result['candidates'].isNotEmpty &&
          result['candidates'][0]['content'] != null &&
          result['candidates'][0]['content']['parts'] != null &&
          result['candidates'][0]['content']['parts'].isNotEmpty) {
        return result['candidates'][0]['content']['parts'][0]['text'];
      }
      return 'Não foi possível obter uma dica.';
    } else {
      throw Exception('Falha ao obter dica da API Gemini: ${response.body}');
    }
  }
}
