import 'package:codepath/pages/pagina_Inicial.dart';
import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(const CodePath()); // Adicionei 'const'

class CodePath extends StatelessWidget {
  const CodePath({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodePath',

      // --- 🚀 ADICIONE ESTAS LINHAS AQUI ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português (Brasil)
        Locale('en', 'US'), // Inglês (como reserva)
      ],

      // --- FIM DAS LINHAS NOVAS ---
      home: const TelaInicial(),
    );
  }
}
