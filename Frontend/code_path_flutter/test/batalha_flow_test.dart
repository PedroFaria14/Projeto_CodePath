import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:codepath/pages/batalha_page.dart';
import 'package:codepath/providers/user_provider.dart';
import 'package:codepath/core/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Retoma o índice persistido e usa correção do servidor sem gabarito local', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await SessionStore.save('token-de-teste', 'aluno@example.org');
    var answerCalls = 0;
    const attemptId = 'tentativa_de_teste_123456789';
    await http.runWithClient(() async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(home: BatalhaPage(
          tipoBatalha: 'ALEATORIA',
          perguntas: [
            {'attempt_id': attemptId, 'tipo': 'multipla_escolha', 'pergunta': 'Já respondida', 'opcoes': ['A', 'B']},
            {'attempt_id': attemptId, 'tipo': 'multipla_escolha', 'pergunta': 'Pergunta retomada', 'opcoes': ['C', 'D']},
          ],
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Pergunta retomada'), findsOneWidget);
      expect(find.text('Acertos: 1'), findsOneWidget);
      expect(find.text('Já respondida'), findsNothing);
      await tester.tap(find.text('C'));
      await tester.pump();
      await tester.ensureVisible(find.text('ENVIAR'));
      await tester.tap(find.text('ENVIAR'));
      await tester.pumpAndSettle();
      expect(answerCalls, 1);
      expect(find.text('Acertos: 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await SessionStore.clear();
    }, () => MockClient((request) async {
      final body = jsonDecode(request.body);
      if (request.url.path == '/game/start') {
        expect(body, {'attempt_id': attemptId});
        return http.Response(jsonEncode({
          'next_index': 1, 'score': 1,
          'deadline': DateTime.now().add(const Duration(seconds: 120)).toUtc().toIso8601String(),
        }), 200, headers: {'content-type': 'application/json'});
      }
      expect(request.url.path, '/game/answer');
      expect(body, {'attempt_id': attemptId, 'index': 1, 'answer': 'C'});
      answerCalls++;
      return http.Response('{"correct":true,"score":2}', 200,
        headers: {'content-type': 'application/json'});
    }));
  });
}
