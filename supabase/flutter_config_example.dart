// ============================================
// UniChat - Configuração Supabase
// Arquivo: lib/core/supabase_config.dart
// 
// INSTRUÇÕES:
// 1. Vá em supabase.com → seu projeto → Settings → API
// 2. Copie o Project URL e a anon key
// 3. Cole abaixo
// ============================================

class SupabaseConfig {
  static const String url = 'https://SEU_PROJECT_ID.supabase.co';
  static const String anonKey = 'SUA_ANON_KEY_AQUI';

  // Nomes das tabelas
  static const String profilesTable = 'profiles';
  static const String chatsTable = 'chats';
  static const String chatParticipantsTable = 'chat_participants';
  static const String messagesTable = 'messages';

  // Storage
  static const String uploadsBucket = 'chat-uploads';

  // Tipos de arquivo aceitos para upload
  static const List<String> allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];
  static const int maxFileSizeMB = 10;
}
