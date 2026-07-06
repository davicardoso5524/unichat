import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';
import 'package:unichat/controllers/auth_controller.dart';
import 'package:unichat/controllers/chat_controller.dart';
import 'package:unichat/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatView extends StatefulWidget {
  final String chatId;
  final String participantName;

  const ChatView({
    super.key,
    required this.chatId,
    required this.participantName,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  int get _chatIdInt => int.parse(widget.chatId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inicia o stream Realtime
      context.read<ChatController>().subscribeToMessages(_chatIdInt);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Para o stream ao sair da tela
    context.read<ChatController>().unsubscribe();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    await context.read<ChatController>().sendMessage(_chatIdInt, content);
  }

  Future<void> _handleAttachment() async {
    await context.read<ChatController>().pickAndSendFile(_chatIdInt);
  }

  void _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthController>().currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(name: widget.participantName, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.participantName,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: Consumer<ChatController>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const LoadingWidget();
                }

                if (chatProvider.messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_outlined,
                    title: 'Nenhuma mensagem',
                    subtitle: 'Envie a primeira mensagem!',
                  );
                }

                // Exibe erro se houver
                if (chatProvider.error != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(chatProvider.error!),
                        backgroundColor: AppColors.destructive,
                      ),
                    );
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    // Reverse: último item = index 0
                    final message = chatProvider.messages[
                        chatProvider.messages.length - 1 - index];
                    final isMe = message.isMe(currentUserId);

                    // Mensagem de arquivo
                    if (message.isFile) {
                      return _FileBubble(
                        message: message,
                        isMe: isMe,
                        time: _formatTime(message.createdAt),
                        onTap: () => _openFile(message.fileUrl!),
                      );
                    }

                    // Mensagem de texto
                    return ChatBubble(
                      isMe: isMe,
                      message: message.content ?? '',
                      time: _formatTime(message.createdAt),
                      senderName: isMe ? null : message.senderName,
                    );
                  },
                );
              },
            ),
          ),
          // Indicador de upload
          Consumer<ChatController>(
            builder: (context, chatProvider, _) {
              if (chatProvider.isUploading) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enviando arquivo...',
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Input de mensagem
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Botão de anexo
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _handleAttachment,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    tooltip: 'Enviar arquivo',
                  ),
                  // Campo de texto
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mensagem...',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botão de enviar
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para exibir mensagem de arquivo (imagem ou documento).
class _FileBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String time;
  final VoidCallback onTap;

  const _FileBubble({
    required this.message,
    required this.isMe,
    required this.time,
    required this.onTap,
  });

  bool get _isImage {
    final url = message.fileUrl?.toLowerCase() ?? '';
    return url.contains('.png') ||
        url.contains('.jpg') ||
        url.contains('.jpeg');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final otherBubbleColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : otherBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe && message.senderName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              // Se é imagem, mostra preview
              if (_isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.fileUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return Container(
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                )
              else
                // Documento (PDF)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      color: isMe ? Colors.white : AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message.content ?? 'Documento',
                        style: TextStyle(
                          color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
