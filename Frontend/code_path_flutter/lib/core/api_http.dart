import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'session_store.dart';

export 'package:http/http.dart' show Response;

VoidCallback? onSessionExpired;
typedef VoidCallback = void Function();

/// Compatibilidade com as chamadas existentes, com uma única política de rede.
/// Nenhuma operação de escrita é repetida automaticamente.
Future<http.Response> _send(
  String method,
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final base = Uri.parse(AppConfig.apiBaseUrl);
  if (url.origin != base.origin) {
    throw ArgumentError('A requisição deve usar a origem configurada da API.');
  }
  final client = http.Client();
  try {
    final request = http.Request(method, url);
    request.followRedirects = false;
    request.headers.addAll(headers ?? {});
    request.headers['Accept'] = 'application/json';
    final token = SessionStore.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (encoding != null) request.encoding = encoding;
    if (body is String) {
      request.body = body;
    } else if (body is List<int>) {
      request.bodyBytes = body;
    } else if (body is Map<String, String>) {
      request.bodyFields = body;
    } else if (body != null) {
      throw ArgumentError('Corpo de requisição não suportado.');
    }
    final response = await (() async {
      final streamed = await client.send(request);
      return http.Response.fromStream(streamed);
    })().timeout(const Duration(seconds: 35));
    if (response.statusCode == 401 && token != null &&
        SessionStore.token == token) {
      await SessionStore.clear();
      onSessionExpired?.call();
    }
    return response;
  } on TimeoutException {
    throw const ApiException('A conexão demorou demais. Tente novamente.');
  } on http.ClientException {
    throw const ApiException('Não foi possível conectar. Verifique sua internet.');
  } finally {
    client.close();
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

String errorMessage(http.Response response, String fallback) {
  try {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map) {
      final detail = data['detail'] ?? data['message'];
      if (detail is String) return detail;
      if (detail is List) return 'Confira os dados preenchidos e tente novamente.';
    }
  } catch (_) {
    // Proxies podem responder HTML durante indisponibilidade.
  }
  return fallback;
}

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    _send('GET', url, headers: headers);
Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _send('POST', url, headers: headers, body: body, encoding: encoding);
Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _send('PUT', url, headers: headers, body: body, encoding: encoding);
Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _send('DELETE', url, headers: headers, body: body, encoding: encoding);
