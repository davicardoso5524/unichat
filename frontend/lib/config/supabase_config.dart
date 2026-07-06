/// Configuração do Supabase para o UniChat.
/// Substitua pelos valores reais do seu projeto.
class SupabaseConfig {
  SupabaseConfig._();

  /// URL do projeto Supabase (Settings → API → Project URL)
  static const String url = 'https://uaopyywgvyxwgskhslpp.supabase.co';

  /// Chave pública anon (Settings → API → anon/public)
  static const String anonKey = 'sb_publishable_lSPSzpf8QHDWGLkwJfidNA_UaeXEXOE';

  // Nomes das tabelas
  static const String profilesTable = 'profiles';
  static const String chatsTable = 'chats';
  static const String chatParticipantsTable = 'chat_participants';
  static const String messagesTable = 'messages';

  // Storage
  static const String uploadsBucket = 'chat-uploads';

  // Upload config
  static const List<String> allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];
  static const int maxFileSizeMB = 10;
}
