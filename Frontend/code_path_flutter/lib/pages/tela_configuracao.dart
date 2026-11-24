import 'package:flutter/material.dart';
import 'package:codepath/core/app_config.dart';
import 'package:codepath/core/api_http.dart' as api;
import 'package:codepath/core/session_store.dart';
import 'package:codepath/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'delete_account_page.dart';
import 'login.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  Future<void> _logout() async {
    try {
      await api.post(Uri.parse('${AppConfig.apiBaseUrl}/logout'));
    } catch (_) {
      // A saída local não depende da disponibilidade da API.
    }
    await SessionStore.clear();

    if (!mounted) return;
    context.read<UserProvider>().reset();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  Future<void> _open(Uri uri) async {
    try {
      if (uri.toString().isEmpty || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Destino indisponível');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível abrir o link. Tente novamente.'),
      ));
    }
  }

  Future<void> _about() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    showAboutDialog(context: context, applicationName: 'CodePath',
      applicationVersion: '${info.version} (${info.buildNumber})',
      children: [const Text('Aprenda lógica de programação com trilhas e desafios.')]);
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
                      subtitle: "Informações e licenças",
                      icon: Icons.info_outline,
                      onTap: _about,
                    ),
                    const Divider(height: 1, indent: 50),
                    // Opção Suporte
                    _buildInfoOption(
                      title: "Ajuda e Suporte",
                      subtitle: "Entre em contato conosco",
                      icon: Icons.help_outline,
                      onTap: () => _open(Uri(scheme: 'mailto', path: AppConfig.supportEmail,
                        queryParameters: {'subject': 'Suporte CodePath'})),
                    ),
                    const Divider(height: 1, indent: 50),
                    // Opção Política
                    _buildInfoOption(
                      title: "Política de Privacidade",
                      icon: Icons.privacy_tip_outlined,
                      onTap: () => _open(Uri.parse(AppConfig.privacyUrl)),
                    ),
                    const Divider(height: 1, indent: 50),
                    _buildInfoOption(
                      title: 'Excluir conta e dados',
                      subtitle: 'Exclusão permanente com confirmação de senha',
                      icon: Icons.delete_forever_outlined,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const DeleteAccountPage())),
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
