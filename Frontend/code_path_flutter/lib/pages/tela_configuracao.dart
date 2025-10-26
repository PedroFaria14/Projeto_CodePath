import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  // Mantém o estado das configurações
  bool modoEscuro = false; // Funcionalidade ainda não implementada
  bool notificacoes = true;
  bool somAtivo = true;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Permite o gradiente ir para trás da AppBar
      appBar: AppBar(
        title: const Text(
          "Configurações",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0, // Sem sombra
        foregroundColor: Colors.white, // Cor dos ícones (seta voltar)
      ),
      body: Container(
        // Fundo gradiente (o mesmo do perfil/login/cadastro)
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFA8E6CF),
              Color(0xFFDCEDC1),
              Color(0xFFFFF3B0),
              Color(0xFFFFD3B6),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            // Usamos ListView para permitir rolagem
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            children: [
              // 🔹 Card flutuante para as opções principais
              _buildModernCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Preferências",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Opção Modo Escuro
                    _buildSwitchOption(
                      title: "Modo escuro",
                      subtitle: "Ativa o tema noturno (em breve)",
                      icon: Icons.dark_mode_outlined,
                      value: modoEscuro,
                      onChanged: null, // Desabilitado por enquanto
                      // onChanged: (value) => setState(() => modoEscuro = value),
                    ),
                    const Divider(height: 1, indent: 50), // Separador
                    // Opção Notificações
                    _buildSwitchOption(
                      title: "Notificações",
                      subtitle: "Receber lembretes e dicas",
                      icon: Icons.notifications_outlined,
                      value: notificacoes,
                      onChanged: (value) =>
                          setState(() => notificacoes = value),
                    ),
                    const Divider(height: 1, indent: 50),
                    // Opção Sons
                    _buildSwitchOption(
                      title: "Som e vibração",
                      subtitle: "Ativa efeitos sonoros do app",
                      icon: Icons.volume_up_outlined,
                      value: somAtivo,
                      onChanged: (value) => setState(() => somAtivo = value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24), // Espaço entre os cards
              // 🔹 Card flutuante para Informações e Suporte
              _buildModernCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sobre e Ajuda",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Opção Versão
                    _buildInfoOption(
                      title: "Versão do app",
                      subtitle: "1.0.0 (Beta)",
                      icon: Icons.info_outline,
                      onTap: () {}, // Nenhuma ação por enquanto
                    ),
                    const Divider(height: 1, indent: 50),
                    // Opção Suporte
                    _buildInfoOption(
                      title: "Ajuda e Suporte",
                      subtitle: "Entre em contato conosco",
                      icon: Icons.help_outline,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Função em desenvolvimento..."),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 50),
                    // Opção Política
                    _buildInfoOption(
                      title: "Política de Privacidade",
                      icon: Icons.privacy_tip_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Página de política em breve..."),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 Botão de Logout (estilo similar ao login)
              ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4, // Sombra
                  shadowColor: Colors.black.withOpacity(0.3),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Sair da conta",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20), // Espaço no final
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

  // Constrói o card branco flutuante (reutilizado do perfil)
  Widget _buildModernCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // Padding interno ajustado
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85), // Um pouco mais opaco
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // Widget para opções com Switch
  Widget _buildSwitchOption({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged, // Permite desabilitar
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF2E2E2E),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            )
          : null,
      secondary: Icon(icon, color: Colors.black54), // Ícone à esquerda
      activeColor: const Color(0xFF3CB371), // Cor verde quando ativo
      value: value,
      onChanged: onChanged, // Usa o callback passado
      contentPadding: const EdgeInsets.symmetric(
        vertical: 4,
      ), // Ajusta padding vertical
    );
  }

  // Widget para opções informativas (sem Switch)
  Widget _buildInfoOption({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54), // Ícone à esquerda
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF2E2E2E),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 16,
      ), // Ajusta padding
      dense: true, // Torna o ListTile mais compacto
    );
  }
}
