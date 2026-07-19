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

  /// Retorna o ID do usuário autenticado. Lança exceção se não estiver logado.
  String get _idUsuarioAtual {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }
    return userId;
  }

  // ─── Conversas ───

  /// Carrega a lista de chats do usuário.
  Future<void> carregarConversas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await _buscarMinhasConversas();
    } catch (e) {
      _error = 'Erro ao carregar conversas.';
      debugPrint('Erro ao carregar chats: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Busca todos os chats do usuário com nome do outro participante
  /// e a última mensagem.
  Future<List<ChatModel>> _buscarMinhasConversas() async {
    final userId = _idUsuarioAtual;

    final myParticipations = await _client
        .from('chat_participants')
        .select(
          'chat_id, chats(id, created_at, is_group, group_name, group_image_url, owner_id)',
        )
        .eq('user_id', userId);

    final List<ChatModel> chats = [];

    for (final participation in myParticipations) {
      final chatData = participation['chats'] as Map<String, dynamic>;
      final chatId = chatData['id'] as int;
      final isGroup = chatData['is_group'] as bool? ?? false;

      String participantName = 'Usuário';
      String participantId = '';
      int memberCount = 0;

      if (isGroup) {
        // Para grupos, usa o nome do grupo
        participantName = chatData['group_name'] as String? ?? 'Grupo';
        // Conta membros
        final membersData = await _client
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chatId);
        memberCount = membersData.length;
      } else {
        // Para chats 1:1, busca o outro participante
        final participants = await _client
            .from('chat_participants')
            .select('user_id, profiles(id, name)')
            .eq('chat_id', chatId)
            .neq('user_id', userId);

        if (participants.isNotEmpty) {
          final profile =
              participants.first['profiles'] as Map<String, dynamic>;
          participantName = profile['name'] as String? ?? 'Usuário';
          participantId = profile['id'] as String? ?? '';
        }
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
        lastMessageTime = DateTime.tryParse(
          msg['created_at']?.toString() ?? '',
        );
      }

      chats.add(
        ChatModel.fromJson(chatData).copyWith(
          participantName: participantName,
          participantId: participantId,
          lastMessage: lastMessage,
          lastMessageTime: lastMessageTime,
          memberCount: memberCount,
        ),
      );
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
  Future<int?> criarConversa(String otherUserId) async {
    try {
      // Refresh da sessão para garantir token válido
      await _client.auth.refreshSession();

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Sem sessão');
      }

      // Logs de diagnóstico da sessão
      debugPrint('=== DEBUG SUPABASE SESSION ===');
      debugPrint('USER: ${_client.auth.currentUser?.id}');
      debugPrint('SESSION: ${_client.auth.currentSession != null}');
      debugPrint(
        'ACCESS TOKEN: ${_client.auth.currentSession?.accessToken != null}',
      );
      debugPrint('EXPIRES: ${_client.auth.currentSession?.expiresAt}');
      debugPrint('ROLE: ${_client.auth.currentSession?.user.role}');
      debugPrint('==============================');

      // Validações
      final myUserId = _idUsuarioAtual;

      if (otherUserId.isEmpty) {
        debugPrint('ERRO: otherUserId está vazio');
        _error = 'Usuário selecionado inválido.';
        notifyListeners();
        return null;
      }

      debugPrint('=== CRIANDO CHAT ===');
      debugPrint('meu id: $myUserId');
      debugPrint('outro id: $otherUserId');

      // Verifica se já existe um chat entre os dois
      final existingChatId = await _buscarConversaExistente(otherUserId);
      if (existingChatId != null) {
        debugPrint('Chat já existe: $existingChatId');
        return existingChatId;
      }

      // Cria o chat via RPC (transação atômica no banco)
      final chatId = await _client.rpc(
        'create_chat',
        params: {'other_user_id': otherUserId},
      );

      debugPrint('=== CHAT CRIADO COM SUCESSO ===');
      debugPrint('chatId: $chatId');
      return chatId as int;
    } catch (e) {
      _error = 'Erro ao criar conversa.';
      debugPrint('=== ERRO AO CRIAR CHAT ===');
      debugPrint('Erro: $e');
      notifyListeners();
      return null;
    }
  }

  /// Busca um chat existente entre o usuário atual e outro usuário.
  Future<int?> _buscarConversaExistente(String otherUserId) async {
    final userId = _idUsuarioAtual;

    final myChats = await _client
        .from('chat_participants')
        .select('chat_id')
        .eq('user_id', userId);

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
  Future<void> buscarUsuarios(String query) async {
    _isSearching = true;
    notifyListeners();

    try {
      final userId = _idUsuarioAtual;
      final myProfileData = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      final myProfile = ProfileModel.fromJson(myProfileData);

      var request = _client.from('profiles').select().neq('id', userId);
      if (!myProfile.ehProfessor && myProfile.course.isNotEmpty) {
        request = request.eq('course', myProfile.course);
      }

      final response = await request;

      List<ProfileModel> profiles = response
          .map((json) => ProfileModel.fromJson(json))
          .toList();

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
  void limparBusca() {
    _searchResults = [];
    notifyListeners();
  }
}
