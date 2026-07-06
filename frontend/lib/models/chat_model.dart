/// Model de chat/conversa (tabela chats do Supabase).
/// O chat em si só tem id e created_at; os participantes vêm de chat_participants.
class ChatModel {
  final int id;
  final DateTime createdAt;

  // Campos derivados (preenchidos via join/lógica no service)
  final String participantName;
  final String participantId;
  final String lastMessage;
  final DateTime? lastMessageTime;

  ChatModel({
    required this.id,
    required this.createdAt,
    this.participantName = 'Usuário',
    this.participantId = '',
    this.lastMessage = '',
    this.lastMessageTime,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as int,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Cria cópia com campos derivados preenchidos.
  ChatModel copyWith({
    String? participantName,
    String? participantId,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return ChatModel(
      id: id,
      createdAt: createdAt,
      participantName: participantName ?? this.participantName,
      participantId: participantId ?? this.participantId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
