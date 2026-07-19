/// Model de chat/conversa (tabela chats do Supabase).
/// Suporta tanto chats 1:1 quanto grupos.
class ChatModel {
  final int id;
  final DateTime createdAt;
  final bool isGroup;
  final String? groupName;
  final String? groupImageUrl;
  final String? ownerId;

  // Campos derivados (preenchidos via join/lógica no service)
  final String participantName;
  final String participantId;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int memberCount;

  ChatModel({
    required this.id,
    required this.createdAt,
    this.isGroup = false,
    this.groupName,
    this.groupImageUrl,
    this.ownerId,
    this.participantName = 'Usuário',
    this.participantId = '',
    this.lastMessage = '',
    this.lastMessageTime,
    this.memberCount = 0,
  });

  /// Nome de exibição: nome do grupo ou nome do participante.
  String get displayName => isGroup ? (groupName ?? 'Grupo') : participantName;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as int,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isGroup: json['is_group'] as bool? ?? false,
      groupName: json['group_name'] as String?,
      groupImageUrl: json['group_image_url'] as String?,
      ownerId: json['owner_id'] as String?,
    );
  }

  /// Cria cópia com campos derivados preenchidos.
  ChatModel copyWith({
    String? participantName,
    String? participantId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? memberCount,
    String? groupName,
    String? groupImageUrl,
  }) {
    return ChatModel(
      id: id,
      createdAt: createdAt,
      isGroup: isGroup,
      groupName: groupName ?? this.groupName,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      ownerId: ownerId,
      participantName: participantName ?? this.participantName,
      participantId: participantId ?? this.participantId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
