import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:codepath/main.dart';
import 'package:codepath/providers/user_provider.dart';
import 'package:codepath/pages/delete_account_page.dart';

void main() {
  testWidgets('Boas-vindas permite iniciar cadastro em tela pequena', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => UserProvider(), child: const CodePath(),
    ));
    expect(find.text('CodePath'), findsOneWidget);
    await tester.ensureVisible(find.text('COMEÇAR AGORA'));
    await tester.tap(find.text('COMEÇAR AGORA'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exclusão exige senha e confirmação antes de chamar API', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MaterialApp(home: DeleteAccountPage()),
    ));
    await tester.ensureVisible(find.text('Excluir minha conta e meus dados'));
    await tester.tap(find.text('Excluir minha conta e meus dados'));
    await tester.pump();
    expect(find.text('Informe sua senha e digite EXCLUIR para confirmar.'), findsOneWidget);
    expect(find.byType(DeleteAccountPage), findsOneWidget);
  });
}
