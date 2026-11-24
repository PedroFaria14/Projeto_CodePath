import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:codepath/core/api_http.dart' as api;
import 'package:codepath/core/app_config.dart';
import 'package:codepath/core/session_store.dart';
import 'package:codepath/providers/user_provider.dart';
import 'login.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});
  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_submitting) return;
    if (_password.text.isEmpty || _confirmation.text != 'EXCLUIR') {
      setState(() => _error = 'Informe sua senha e digite EXCLUIR para confirmar.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _submitting = true; _error = null; });
    try {
      final response = await api.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': _password.text, 'confirmation': _confirmation.text}),
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        throw api.ApiException(api.errorMessage(response, 'Não foi possível concluir a exclusão. Tente novamente.'));
      }
      await SessionStore.clear();
      if (!mounted) return;
      context.read<UserProvider>().reset();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()), (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua conta foi excluída.')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error is api.ApiException
          ? error.message : 'Não foi possível concluir. Verifique a conexão e tente novamente.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: Scaffold(
      appBar: AppBar(title: const Text('Excluir conta')),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.delete_forever_outlined, size: 56, color: Colors.red),
          const SizedBox(height: 24),
          Text('Esta ação é permanente', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text('Seu perfil, progresso, moedas, ranking, amizades, convites e notificações '
              'serão removidos. Partidas compartilhadas também serão removidas. '
              'Não é possível recuperar sua conta depois da exclusão.'),
          const SizedBox(height: 24),
          TextField(controller: _password, obscureText: true, enabled: !_submitting,
            enableSuggestions: false, autocorrect: false,
            decoration: const InputDecoration(labelText: 'Senha atual', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _confirmation, enabled: !_submitting,
            decoration: const InputDecoration(labelText: 'Digite EXCLUIR', border: OutlineInputBorder())),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16),
            child: Semantics(liveRegion: true, child: Text(_error!, style: const TextStyle(color: Colors.red)))),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _submitting ? null : _delete,
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(48)),
            icon: _submitting ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete_outline),
            label: Text(_submitting ? 'Excluindo…' : 'Excluir minha conta e meus dados')),
        ]),
      )),
    ),
  );
}
