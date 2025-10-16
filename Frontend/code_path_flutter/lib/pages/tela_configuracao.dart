import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  bool modoEscuro = false;
  bool notificacoes = true;
  bool somAtivo = true;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF5E1),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Configurações"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          // 🔹 Tema
          SwitchListTile(
            title: const Text("Modo escuro"),
            subtitle: const Text("Ativa o tema noturno"),
            activeColor: Colors.green,
            value: modoEscuro,
            onChanged: (value) {
              setState(() => modoEscuro = value);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),

          // 🔹 Notificações
          SwitchListTile(
            title: const Text("Notificações"),
            subtitle: const Text("Receber lembretes e dicas"),
            activeColor: Colors.green,
            value: notificacoes,
            onChanged: (value) {
              setState(() => notificacoes = value);
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),

          // 🔹 Sons
          SwitchListTile(
            title: const Text("Som e vibração"),
            subtitle: const Text("Ativa sons do app"),
            activeColor: Colors.green,
            value: somAtivo,
            onChanged: (value) {
              setState(() => somAtivo = value);
            },
            secondary: const Icon(Icons.volume_up),
          ),
          const Divider(),

          // 🔹 Versão
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Versão do app"),
            subtitle: const Text("1.0.0 (Beta)"),
            onTap: () {},
          ),
          const Divider(),

          // 🔹 Suporte
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Ajuda e Suporte"),
            subtitle: const Text("Entre em contato com o suporte"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Função em desenvolvimento...")),
              );
            },
          ),
          const Divider(),

          // 🔹 Política
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Política de Privacidade"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Página de política em breve...")),
              );
            },
          ),
          const SizedBox(height: 30),

          // 🔹 Botão de Logout
          ElevatedButton.icon(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              "Sair da conta",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
