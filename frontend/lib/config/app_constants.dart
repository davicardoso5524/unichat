/// Constantes globais do aplicativo UniChat.
class AppConstants {
  AppConstants._();

  /// URL base do backend FastAPI.
  /// Altere para o IP/URL do servidor em produção.
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Nome do aplicativo.
  static const String appName = 'UniChat';

  /// Slogan.
  static const String slogan = 'Sua universidade conversa aqui.';

  /// Versão.
  static const String version = 'v1.0 · Beta';

  /// Chave para armazenar token localmente.
  static const String tokenKey = 'auth_token';
}
