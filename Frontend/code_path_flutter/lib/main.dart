// Arquivo: main.dart (Corrigido)
import 'package:codepath/pages/pagina_Inicial.dart';
import 'package:flutter/material.dart';
// import 'pages/login.dart'; // (Removido se não for usado aqui)
import 'providers/user_provider.dart'; // <--- 1. IMPORTE O SEU PROVIDER
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // <--- 2. IMPORTE O PACOTE PROVIDER

// 👇 3. SUA FUNÇÃO 'main' DEVE FICAR ASSIM
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(), // Cria o "cérebro"
      child: const CodePath(), // Seu app 'CodePath' vai aqui
    ),
  );
}

class CodePath extends StatelessWidget {
  const CodePath({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodePath',

      // Suas localizações (isso está correto!)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],

      home: const TelaInicial(),
    );
  }
}
