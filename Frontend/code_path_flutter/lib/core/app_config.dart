import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://projeto-codepath.onrender.com',
  );
  static String get apiBaseUrl => _apiBaseUrl.endsWith('/')
      ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 1) : _apiBaseUrl;
  static const privacyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const deletionUrl = String.fromEnvironment('ACCOUNT_DELETION_URL');

  static void validate() {
    final api = Uri.tryParse(apiBaseUrl);
    if (api == null || api.scheme != 'https' || api.host.isEmpty ||
        api.userInfo.isNotEmpty || api.hasQuery || api.hasFragment ||
        (api.path.isNotEmpty && api.path != '/')) {
      throw StateError('API_BASE_URL deve ser uma origem HTTPS válida.');
    }
    if (kReleaseMode) {
      for (final value in [privacyUrl, deletionUrl]) {
        final uri = Uri.tryParse(value);
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          throw StateError('Configure as URLs públicas de privacidade e exclusão.');
        }
      }
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(supportEmail)) {
        throw StateError('Configure SUPPORT_EMAIL com o contato de suporte.');
      }
    }
  }
}
