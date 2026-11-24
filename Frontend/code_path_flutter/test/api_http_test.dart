import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:codepath/core/api_http.dart' as api;
import 'package:codepath/core/app_config.dart';
import 'package:codepath/core/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await SessionStore.clear();
    api.onSessionExpired = null;
  });

  test('E-mail legado sozinho não restaura uma sessão', () async {
    SharedPreferences.setMockInitialValues({'userEmail': 'antigo@example.org'});
    await SessionStore.restore();
    expect(SessionStore.token, isNull);
    expect((await SharedPreferences.getInstance()).getString('userEmail'), isNull);
  });

  test('Envia token e JSON preservando espaços na senha', () async {
    await SessionStore.save('token-de-teste', 'aluno@example.org');
    await http.runWithClient(() async {
      final response = await api.post(Uri.parse('${AppConfig.apiBaseUrl}/account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': ' senha com espaços '}));
      expect(response.statusCode, 200);
    }, () => MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer token-de-teste');
      expect(jsonDecode(request.body)['password'], ' senha com espaços ');
      return http.Response('{}', 200);
    }));
  });

  test('Não envia credenciais para outra origem', () async {
    await SessionStore.save('token-de-teste', 'aluno@example.org');
    await expectLater(api.get(Uri.parse('https://outra-origem.example/profile')),
      throwsArgumentError);
  });

  test('401 revoga sessão local e avisa a navegação', () async {
    await SessionStore.save('token-de-teste', 'aluno@example.org');
    var expired = false;
    api.onSessionExpired = () => expired = true;
    await http.runWithClient(() => api.get(Uri.parse('${AppConfig.apiBaseUrl}/profile/aluno')),
      () => MockClient((_) async => http.Response('{}', 401)));
    expect(SessionStore.token, isNull);
    expect(expired, isTrue);
  });

  test('Falha de validação e HTML do proxy geram mensagens compreensíveis', () {
    expect(api.errorMessage(http.Response('{"detail":[{"msg":"invalid"}]}', 422), 'erro'),
      'Confira os dados preenchidos e tente novamente.');
    expect(api.errorMessage(http.Response('<html>indisponível</html>', 503), 'Tente novamente.'),
      'Tente novamente.');
  });
}
