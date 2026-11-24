import 'package:codepath/pages/cadastro.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:codepath/core/app_config.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.1, 0.6, 1.0],
            colors: [Color(0xFFE0F8E0), Color(0xFFB2F7C1), Color(0xFF90EE90)],
          ),
        ),
        child: SafeArea(child: Center(
          child: SingleChildScrollView(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/imagens/gato1.png", height: 200),

                const SizedBox(height: 24),
                const Text(
                  "CodePath",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  "Aprenda lógica de programação,\num desafio de cada vez.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3CB371).withOpacity(0.7),
                          offset: const Offset(0, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3CB371),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Cadastro(),
                          ),
                        );
                      },

                      child: const Text(
                        "COMEÇAR AGORA",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                if (AppConfig.privacyUrl.isNotEmpty) TextButton(
                  onPressed: () async {
                    try {
                      final opened = await launchUrl(Uri.parse(AppConfig.privacyUrl),
                          mode: LaunchMode.externalApplication);
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Não foi possível abrir a política. Tente novamente.')));
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Não foi possível abrir a política. Tente novamente.')));
                      }
                    }
                  },
                  child: const Text('Política de privacidade'),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 81, 46, 143),
                          offset: Offset(0, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 63, 32, 117),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        elevation: 0,
                      ),

                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      ),

                      child: const Text(
                        "Ir para Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ))),
        )),
      ),
    );
  }
}
