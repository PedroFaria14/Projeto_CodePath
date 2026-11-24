import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O e-mail em preferências é apenas cache de apresentação, nunca autenticação.
abstract final class SessionStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static String? _token;
  static String? get token => _token;

  static Future<void> restore() async {
    _token = await _storage.read(key: 'session_token');
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userEmail');
    }
  }

  static Future<void> save(String token, String email) async {
    if (token.isEmpty) throw StateError('A API não retornou uma sessão válida.');
    await _storage.write(key: 'session_token', value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
    _token = token;
  }

  static Future<void> clear() async {
    _token = null;
    await _storage.delete(key: 'session_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');
  }
}
