import 'package:unichat/widgets/message_status_icon.dart';

/// Model de mensagem (tabela messages do Supabase).
class MessageModel {
  final int id;
  final int chatId;
  final String senderId;
  final String? content;
  final String? fileUrl;
  final DateTime createdAt;
  final MessageStatus status;

  // Campo derivado do join com profiles
  final String senderName;
  final String senderRole;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.fileUrl,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.senderName = '',
    this.senderRole = 'student',
  });

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    String? idUsuarioAtual,
  }) {
    // O join com profiles retorna: { ..., profiles: { name: "...", role: "..." } }
    final profiles = json['profiles'] as Map<String, dynamic>?;
    final senderName = profiles?['name'] as String? ?? '';
    final senderRole = profiles?['role'] as String? ?? 'student';

    // Parse status
    final statusStr = json['status'] as String? ?? 'sent';
    final status = MessageStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => MessageStatus.sent,
    );

    return MessageModel(
      id: json['id'] as int,
      chatId: json['chat_id'] as int,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      fileUrl: json['file_url'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      status: status,
      senderName: senderName,
      senderRole: senderRole,
    );
  }

  /// Se a mensagem é do usuário atual.
  bool ehMinha(String idUsuarioAtual) => senderId == idUsuarioAtual;

  /// Se é mensagem de arquivo.
  bool get ehArquivo => fileUrl != null && fileUrl!.isNotEmpty;

  /// Se o remetente da mensagem é professor.
  bool get foiEnviadaPorProfessor => senderRole == 'professor';

  /// Texto para exibição (content ou nome do arquivo).
  String get textoExibicao {
    if (content != null && content!.isNotEmpty) return content!;
    if (ehArquivo) return '📎 Arquivo';
    return '';
  }
}

/// Model para mensagem fixada.
class PinnedMessageModel {
  final int id;
  final int chatId;
  final int messageId;
  final String pinnedBy;
  final DateTime pinnedAt;
  final DateTime expiresAt;
  final MessageModel? message;

  PinnedMessageModel({
    required this.id,
    required this.chatId,
    required this.messageId,
    required this.pinnedBy,
    required this.pinnedAt,
    required this.expiresAt,
    this.message,
  });

  bool get estaExpirada => DateTime.now().isAfter(expiresAt);

  String get tempoRestante {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expirado';
    if (diff.inDays > 0) return '${diff.inDays}d restantes';
    if (diff.inHours > 0) return '${diff.inHours}h restantes';
    return '${diff.inMinutes}min restantes';
  }

  factory PinnedMessageModel.fromJson(Map<String, dynamic> json) {
    MessageModel? message;
    if (json['messages'] != null && json['messages'] is Map<String, dynamic>) {
      final msgData = json['messages'] as Map<String, dynamic>;
      message = MessageModel.fromJson({
        ...msgData,
        'chat_id': msgData['chat_id'] ?? json['chat_id'],
      });
    }

    return PinnedMessageModel(
      id: json['id'] as int,
      chatId: json['chat_id'] as int,
      messageId: json['message_id'] as int,
      pinnedBy: json['pinned_by'] as String,
      pinnedAt:
          DateTime.tryParse(json['pinned_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.now(),
      message: message,
    );
  }
}
