import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:unichat/config/supabase_config.dart';
import 'package:unichat/models/models.dart';

/// Controller da tela de chat — mensagens em tempo real (Realtime) e uploads.
///
/// Fold do antigo ChatController + ChatService (mensagens) + StorageService.
class ChatController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();
  StreamSubscription? _messagesSubscription;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;

  String get _currentUserId => _client.auth.currentUser!.id;

  // ─── Mensagens ───

  /// Busca as mensagens de um chat (com nome do sender via join profiles).
  Future<List<MessageModel>> _fetchMessages(int chatId) async {
    final response = await _client
        .from('messages')
        .select('*, profiles(name)')
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    return response.map((json) => MessageModel.fromJson(json)).toList();
  }

  /// Inicia o stream Realtime de mensagens de um chat.
  void subscribeToMessages(int chatId) {
    _isLoading = true;
    notifyListeners();

    _messagesSubscription?.cancel();

    final stream = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at');

    _messagesSubscription = stream.listen(
      (data) async {
        // O stream não traz o join com profiles; buscamos completo.
        try {
          _messages = await _fetchMessages(chatId);
          _isLoading = false;
          notifyListeners();
        } catch (e) {
          debugPrint('Erro ao atualizar mensagens: $e');
        }
      },
      onError: (error) {
        debugPrint('Erro no stream de mensagens: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Carrega mensagens iniciais (sem Realtime, fallback).
  Future<void> loadMessages(int chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _fetchMessages(chatId);
    } catch (e) {
      _error = 'Erro ao carregar mensagens.';
      debugPrint('Erro ao carregar mensagens: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Envia uma mensagem de texto.
  Future<void> sendMessage(int chatId, String content) async {
    try {
      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': _currentUserId,
        'content': content,
      });
      // O Realtime atualiza a lista automaticamente.
    } catch (e) {
      _error = 'Erro ao enviar mensagem.';
      debugPrint('Erro ao enviar mensagem: $e');
      notifyListeners();
    }
  }

  // ─── Upload de arquivos ───

  /// Seleciona um arquivo, faz upload no Storage e envia como mensagem.
  Future<void> pickAndSendFile(int chatId) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final extension = file.extension?.toLowerCase() ?? '';

      // Validações
      if (!_isAllowedExtension(extension)) {
        _error = 'Tipo de arquivo não permitido. Use PDF, PNG ou JPG.';
        notifyListeners();
        return;
      }

      if (file.size > 0 && !_isWithinSizeLimit(file.size)) {
        _error = 'Arquivo muito grande. Máximo: 10MB.';
        notifyListeners();
        return;
      }

      _isUploading = true;
      notifyListeners();

      final fileName = '${_uuid.v4()}.$extension';
      final storagePath = '$_currentUserId/$fileName';
      final bucket = _client.storage.from(SupabaseConfig.uploadsBucket);

      if (file.bytes != null) {
        // Web ou quando os bytes estão disponíveis.
        await bucket.uploadBinary(storagePath, file.bytes!);
      } else if (file.path != null) {
        // Mobile/desktop com caminho do arquivo.
        await bucket.upload(storagePath, File(file.path!));
      } else {
        _error = 'Não foi possível ler o arquivo.';
        _isUploading = false;
        notifyListeners();
        return;
      }

      final fileUrl = bucket.getPublicUrl(storagePath);

      // Envia a mensagem com o file_url.
      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': _currentUserId,
        'content': file.name,
        'file_url': fileUrl,
      });

      _isUploading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao enviar arquivo.';
      _isUploading = false;
      debugPrint('Erro ao enviar arquivo: $e');
      notifyListeners();
    }
  }

  bool _isAllowedExtension(String extension) {
    return SupabaseConfig.allowedExtensions.contains(extension.toLowerCase());
  }

  bool _isWithinSizeLimit(int sizeInBytes) {
    final maxBytes = SupabaseConfig.maxFileSizeMB * 1024 * 1024;
    return sizeInBytes <= maxBytes;
  }

  /// Verifica se uma mensagem é do usuário atual.
  bool isMyMessage(MessageModel message) {
    return message.senderId == _currentUserId;
  }

  /// Para o stream de mensagens.
  void unsubscribe() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _messages = [];
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
