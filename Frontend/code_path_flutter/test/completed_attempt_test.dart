import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:codepath/core/session_store.dart';
import 'package:codepath/pages/batalha_page.dart';
import 'package:codepath/pages/desafio_page.dart';
import 'package:codepath/providers/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final weekly in [false, true]) {
    testWidgets('Última resposta persistida não acessa índice inválido (${weekly ? 'semanal' : 'batalha'})', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      await SessionStore.save('token-de-teste', 'aluno@example.org');
      final finish = Completer<http.Response>();
      var finishCalls = 0;
      final questions = <Map<String, dynamic>>[{
        'attempt_id': 'tentativa_concluida_123456789', 'tipo': 'multipla_escolha',
        'fase': 1, 'pergunta': 'Já respondida', 'opcoes': ['A', 'B'],
      }];
      await http.runWithClient(() async {
        await tester.pumpWidget(ChangeNotifierProvider(
          create: (_) => UserProvider(),
          child: MaterialApp(home: weekly ? const DesafioPage() : BatalhaPage(
            perguntas: questions, tipoBatalha: 'ALEATORIA')),
        ));
        await tester.pump();
        if (weekly) {
          await tester.pump(const Duration(milliseconds: 350));
          await tester.ensureVisible(find.text('COMEÇAR'));
          await tester.tap(find.text('COMEÇAR'));
        }
        for (var frame = 0; frame < 10; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(finishCalls, 1);
        expect(find.text('Todas as respostas foram salvas. Finalizando resultado…'), findsOneWidget);
        expect(tester.takeException(), isNull);
        finish.complete(http.Response('{"detail":"Falha temporária"}', 503));
        for (var frame = 0; frame < 5; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await SessionStore.clear();
      }, () => MockClient((request) async {
        if (request.url.path == '/desafio/iniciar') {
          return http.Response(jsonEncode({'perguntas': questions}), 200);
        }
        if (request.url.path == '/game/start') {
          return http.Response(jsonEncode({
            'next_index': 1, 'score': 1,
            'deadline': DateTime.now().add(const Duration(seconds: 30)).toUtc().toIso8601String(),
          }), 200);
        }
        expect(request.url.path, weekly ? '/desafio/finalizar' : '/batalha/finalizar');
        finishCalls++;
        return finish.future;
      }));
    });
  }
}
