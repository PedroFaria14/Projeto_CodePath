// Arquivo: main.dart (Corrigido)
import 'package:codepath/pages/pagina_Inicial.dart';
import 'package:flutter/material.dart';
// import 'pages/login.dart'; // (Removido se não for usado aqui)
import 'providers/user_provider.dart'; // <--- 1. IMPORTE O SEU PROVIDER
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // <--- 2. IMPORTE O PACOTE PROVIDER
import 'core/app_config.dart';
import 'core/session_store.dart';
import 'core/api_http.dart' as api;
import 'pages/home.dart';
import 'pages/login.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

// 👇 3. SUA FUNÇÃO 'main' DEVE FICAR ASSIM
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  try {
    await SessionStore.restore();
  } catch (_) {
    // Preferências/keystore restaurados de outro dispositivo podem ser inválidos.
    await SessionStore.clear();
  }
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
    api.onSessionExpired = () {
      context.read<UserProvider>().reset();
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()), (_) => false,
      );
    };
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CodePath',

      // Suas localizações (isso está correto!)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],

      home: SessionStore.token == null ? const TelaInicial() : const PaginaHome(),
    );
  }
}
