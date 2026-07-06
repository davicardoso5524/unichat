import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unichat/models/models.dart';

/// Controller da Home — lista de conversas e busca de contatos.
///
/// Fold do antigo HomeController + parte do ChatService (chats/contatos).
class HomeController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  HomeController();

  List<ChatModel> _chats = [];
  List<ProfileModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<ChatModel> get chats => _chats;
  List<ProfileModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  String get _currentUserId => _client.auth.currentUser!.id;

  // ─── Conversas ───

  /// Carrega a lista de chats do usuário.
  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await _fetchMyChats();
    } catch (e) {
      _error = 'Erro ao carregar conversas.';
      debugPrint('Erro ao carregar chats: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Busca todos os chats do usuário com nome do outro participante
  /// e a última mensagem.
  Future<List<ChatModel>> _fetchMyChats() async {
    final myParticipations = await _client
        .from('chat_participants')
        .select('chat_id, chats(id, created_at)')
        .eq('user_id', _currentUserId);

    final List<ChatModel> chats = [];

    for (final participation in myParticipations) {
      final chatData = participation['chats'] as Map<String, dynamic>;
      final chatId = chatData['id'] as int;

      // Busca o outro participante.
      final participants = await _client
          .from('chat_participants')
          .select('user_id, profiles(id, name)')
          .eq('chat_id', chatId)
          .neq('user_id', _currentUserId);

      String participantName = 'Usuário';
      String participantId = '';
      if (participants.isNotEmpty) {
        final profile = participants.first['profiles'] as Map<String, dynamic>;
        participantName = profile['name'] as String? ?? 'Usuário';
        participantId = profile['id'] as String? ?? '';
      }

      // Busca a última mensagem.
      final lastMessages = await _client
          .from('messages')
          .select('content, file_url, created_at')
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(1);

      String lastMessage = '';
      DateTime? lastMessageTime;
      if (lastMessages.isNotEmpty) {
        final msg = lastMessages.first;
        final content = msg['content'] as String?;
        final fileUrl = msg['file_url'] as String?;
        lastMessage = content ?? (fileUrl != null ? '📎 Arquivo' : '');
        lastMessageTime =
            DateTime.tryParse(msg['created_at']?.toString() ?? '');
      }

      chats.add(ChatModel.fromJson(chatData).copyWith(
        participantName: participantName,
        participantId: participantId,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
      ));
    }

    // Ordena por última mensagem (mais recente primeiro).
    chats.sort((a, b) {
      final aTime = a.lastMessageTime ?? a.createdAt;
      final bTime = b.lastMessageTime ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return chats;
  }

  /// Cria um novo chat com outro usuário e retorna o chatId.
  Future<int?> createChat(String otherUserId) async {
    try {
      final existingChatId = await _findExistingChat(otherUserId);
      if (existingChatId != null) {
        await loadChats();
        return existingChatId;
      }

      // Cria o chat.
      final chat =
          await _client.from('chats').insert({}).select().single();
      final chatId = chat['id'] as int;

      // Adiciona os dois participantes.
      await _client.from('chat_participants').insert([
        {'chat_id': chatId, 'user_id': _currentUserId},
        {'chat_id': chatId, 'user_id': otherUserId},
      ]);

      await loadChats();
      return chatId;
    } catch (e) {
      _error = 'Erro ao criar conversa.';
      debugPrint('Erro ao criar chat: $e');
      notifyListeners();
      return null;
    }
  }

  /// Busca um chat existente entre o usuário atual e outro usuário.
  Future<int?> _findExistingChat(String otherUserId) async {
    final myChats = await _client
        .from('chat_participants')
        .select('chat_id')
        .eq('user_id', _currentUserId);

    for (final row in myChats) {
      final chatId = row['chat_id'] as int;
      final otherParticipant = await _client
          .from('chat_participants')
          .select('user_id')
          .eq('chat_id', chatId)
          .eq('user_id', otherUserId);

      if (otherParticipant.isNotEmpty) {
        return chatId;
      }
    }
    return null;
  }

  // ─── Contatos ───

  /// Busca perfis (exceto o usuário atual) para iniciar uma conversa.
  Future<void> searchUsers(String query) async {
    _isSearching = true;
    notifyListeners();

    try {
      final response =
          await _client.from('profiles').select().neq('id', _currentUserId);

      List<ProfileModel> profiles =
          response.map((json) => ProfileModel.fromJson(json)).toList();

      if (query.isNotEmpty) {
        final lower = query.toLowerCase();
        profiles = profiles.where((p) {
          return p.name.toLowerCase().contains(lower) ||
              p.email.toLowerCase().contains(lower);
        }).toList();
      }

      _searchResults = profiles;
    } catch (e) {
      debugPrint('Erro ao buscar usuários: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Limpa os resultados de busca.
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
