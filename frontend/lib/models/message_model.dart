/// Model de mensagem (tabela messages do Supabase).
class MessageModel {
  final int id;
  final int chatId;
  final String senderId;
  final String? content;
  final String? fileUrl;
  final DateTime createdAt;

  // Campo derivado do join com profiles
  final String senderName;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.fileUrl,
    required this.createdAt,
    this.senderName = '',
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // O join com profiles retorna: { ..., profiles: { name: "..." } }
    final profiles = json['profiles'] as Map<String, dynamic>?;
    final senderName = profiles?['name'] as String? ?? '';

    return MessageModel(
      id: json['id'] as int,
      chatId: json['chat_id'] as int,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      fileUrl: json['file_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      senderName: senderName,
    );
  }

  /// Se a mensagem é do usuário atual.
  bool isMe(String currentUserId) => senderId == currentUserId;

  /// Se é mensagem de arquivo.
  bool get isFile => fileUrl != null && fileUrl!.isNotEmpty;

  /// Texto para exibição (content ou nome do arquivo).
  String get displayText {
    if (content != null && content!.isNotEmpty) return content!;
    if (isFile) return '📎 Arquivo';
    return '';
  }
}
