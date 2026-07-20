import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unichat/models/models.dart';

class HomeController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  HomeController();

  RealtimeChannel? _conversasChannel;
  List<ChatModel> _chats = [];
  List<ProfileModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _estaAtualizandoConversas = false;
  bool _atualizarConversasDepois = false;
  String? _error;

  List<ChatModel> get chats => _chats;
  List<ProfileModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  String get _idUsuarioAtual {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }
    return userId;
  }

  void assinarConversas() {
    cancelarAssinaturaConversas();

    final userId = _idUsuarioAtual;
    _conversasChannel = _client
        .channel('conversas:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _atualizarConversasEmSegundoPlano(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _atualizarConversasEmSegundoPlano(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          callback: (_) => _atualizarConversasEmSegundoPlano(),
        )
        .subscribe();

    carregarConversas();
  }

  void cancelarAssinaturaConversas() {
    final channel = _conversasChannel;
    if (channel == null) return;
    _conversasChannel = null;
    unawaited(_client.removeChannel(channel));
  }

  Future<void> _atualizarConversasEmSegundoPlano() async {
    if (_estaAtualizandoConversas) {
      _atualizarConversasDepois = true;
      return;
    }

    _estaAtualizandoConversas = true;
    do {
      _atualizarConversasDepois = false;
      await carregarConversas(mostrarCarregando: false);
    } while (_atualizarConversasDepois);
    _estaAtualizandoConversas = false;
  }

  Future<void> carregarConversas({bool mostrarCarregando = true}) async {
    if (mostrarCarregando) {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      _chats = await _buscarMinhasConversas();
    } catch (e) {
      _error = 'Erro ao carregar conversas.';
      debugPrint('Erro ao carregar chats: $e');
    }

    if (mostrarCarregando) {
      _isLoading = false;
    }
    notifyListeners();
  }

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
        participantName = chatData['group_name'] as String? ?? 'Grupo';
        final membersData = await _client
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chatId);
        memberCount = membersData.length;
      } else {
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

    chats.sort((a, b) {
      final aTime = a.lastMessageTime ?? a.createdAt;
      final bTime = b.lastMessageTime ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return chats;
  }

  Future<int?> criarConversa(String otherUserId) async {
    try {
      await _client.auth.refreshSession();

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Sem sessão');
      }

      if (otherUserId.isEmpty) {
        _error = 'Usuário selecionado inválido.';
        notifyListeners();
        return null;
      }

      final existingChatId = await _buscarConversaExistente(otherUserId);
      if (existingChatId != null) {
        return existingChatId;
      }

      final chatId = await _client.rpc(
        'create_chat',
        params: {'other_user_id': otherUserId},
      );

      return chatId as int;
    } catch (e) {
      _error = 'Erro ao criar conversa.';
      debugPrint('Erro ao criar chat: $e');
      notifyListeners();
      return null;
    }
  }

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

  void limparBusca() {
    _searchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    cancelarAssinaturaConversas();
    super.dispose();
  }
}
