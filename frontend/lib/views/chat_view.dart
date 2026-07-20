import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';
import 'package:unichat/controllers/auth_controller.dart';
import 'package:unichat/controllers/chat_controller.dart';
import 'package:unichat/controllers/group_controller.dart';
import 'package:unichat/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatView extends StatefulWidget {
  final String chatId;
  final String participantName;
  final bool isGroup;
  final String? groupImageUrl;

  const ChatView({
    super.key,
    required this.chatId,
    required this.participantName,
    this.isGroup = false,
    this.groupImageUrl,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<PinnedMessageModel> _pinnedMessages = [];

  int get _chatIdInt => int.parse(widget.chatId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().assinarMensagens(_chatIdInt);
      _carregarMensagensFixadas();
      context.read<ChatController>().marcarComoLidas(_chatIdInt);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatController>().cancelarAssinatura();
    super.dispose();
  }

  Future<void> _carregarMensagensFixadas() async {
    if (widget.isGroup) {
      final pinned = await context
          .read<GroupController>()
          .buscarMensagensFixadas(_chatIdInt);
      if (mounted) {
        setState(() => _pinnedMessages = pinned);
      }
    }
  }

  Future<void> _enviarMensagem() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    await context.read<ChatController>().enviarMensagem(_chatIdInt, content);
  }

  Future<void> _enviarAnexo() async {
    await context.read<ChatController>().selecionarEEnviarArquivo(_chatIdInt);
  }

  void _abrirArquivo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatarHora(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _mostrarOpcoesFixar(MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Fixar mensagem',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Fixar por 24 horas'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<GroupController>().fixarMensagem(
                  _chatIdInt,
                  message.id,
                  hours: 24,
                );
                _carregarMensagensFixadas();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Fixar por 7 dias'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<GroupController>().fixarMensagem(
                  _chatIdInt,
                  message.id,
                  hours: 168,
                );
                _carregarMensagensFixadas();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idUsuarioAtual = context.read<AuthController>().idUsuarioAtual ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: widget.isGroup
              ? () => context.push('/group/${widget.chatId}/details')
              : null,
          child: Row(
            children: [
              widget.isGroup
                  ? Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                        image: widget.groupImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(widget.groupImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.groupImageUrl == null
                          ? const Icon(Icons.group, size: 20)
                          : null,
                    )
                  : AvatarWidget(name: widget.participantName, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.participantName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.isGroup)
                      Text(
                        'Toque para detalhes',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_pinnedMessages.isNotEmpty)
            GestureDetector(
              onTap: () {
                final pinnedMsgId = _pinnedMessages.first.messageId;
                final chatProvider = context.read<ChatController>();
                final msgIndex = chatProvider.messages.indexWhere(
                  (m) => m.id == pinnedMsgId,
                );
                if (msgIndex != -1) {
                  final reverseIndex =
                      chatProvider.messages.length - 1 - msgIndex;
                  _scrollController.animateTo(
                    reverseIndex * 60.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pinnedMessages.first.message?.content ??
                                'Mensagem fixada',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _pinnedMessages.first.tempoRestante,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () async {
                        await context.read<GroupController>().desafixarMensagem(
                          _chatIdInt,
                          _pinnedMessages.first.messageId,
                        );
                        _carregarMensagensFixadas();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

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
                    final message = chatProvider
                        .messages[chatProvider.messages.length - 1 - index];
                    final ehMinha = message.ehMinha(idUsuarioAtual);

                    return GestureDetector(
                      onLongPress: widget.isGroup
                          ? () => _mostrarOpcoesFixar(message)
                          : null,
                      child: message.ehArquivo
                          ? _FileBubble(
                              message: message,
                              isMe: ehMinha,
                              time: _formatarHora(message.createdAt),
                              status: message.status,
                              showStatus: ehMinha,
                              onTap: () => _abrirArquivo(message.fileUrl!),
                            )
                          : _TextBubble(
                              message: message,
                              isMe: ehMinha,
                              time: _formatarHora(message.createdAt),
                              showSenderName: widget.isGroup && !ehMinha,
                            ),
                    );
                  },
                );
              },
            ),
          ),

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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
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
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _enviarAnexo,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    tooltip: 'Enviar arquivo',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mensagem...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
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
                      onSubmitted: (_) => _enviarMensagem(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      onPressed: _enviarMensagem,
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

class _TextBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String time;
  final bool showSenderName;

  const _TextBubble({
    required this.message,
    required this.isMe,
    required this.time,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final otherBubbleColor = isDark
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.primaryContainer;
    final ehMensagemProfessor = message.foiEnviadaPorProfessor && !isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primary : otherBubbleColor,
          border: ehMensagemProfessor
              ? Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.55),
                )
              : null,
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
            if ((showSenderName && message.senderName.isNotEmpty) ||
                ehMensagemProfessor)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSenderName && message.senderName.isNotEmpty)
                      Flexible(
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMe
                                ? onPrimary.withValues(alpha: 0.72)
                                : primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (showSenderName &&
                        message.senderName.isNotEmpty &&
                        ehMensagemProfessor)
                      const SizedBox(width: 6),
                    if (ehMensagemProfessor) const ProfessorBadge(),
                  ],
                ),
              ),
            Text(
              message.content ?? '',
              style: TextStyle(
                color: isMe ? onPrimary : theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? onPrimary.withValues(alpha: 0.72)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  MessageStatusIcon(
                    status: message.status,
                    size: 14,
                    isDark: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String time;
  final MessageStatus status;
  final bool showStatus;
  final VoidCallback onTap;

  const _FileBubble({
    required this.message,
    required this.isMe,
    required this.time,
    required this.status,
    required this.showStatus,
    required this.onTap,
  });

  bool get _ehImagem {
    final url = message.fileUrl?.toLowerCase() ?? '';
    return url.contains('.png') ||
        url.contains('.jpg') ||
        url.contains('.jpeg');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final otherBubbleColor = isDark
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.primaryContainer;
    final ehMensagemProfessor = message.foiEnviadaPorProfessor && !isMe;

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
            color: isMe ? primary : otherBubbleColor,
            border: ehMensagemProfessor
                ? Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.55),
                  )
                : null,
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
              if ((!isMe && message.senderName.isNotEmpty) ||
                  ehMensagemProfessor)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe && message.senderName.isNotEmpty)
                        Flexible(
                          child: Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (!isMe &&
                          message.senderName.isNotEmpty &&
                          ehMensagemProfessor)
                        const SizedBox(width: 6),
                      if (ehMensagemProfessor) const ProfessorBadge(),
                    ],
                  ),
                ),
              if (_ehImagem)
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      color: isMe ? onPrimary : primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message.content ?? 'Documento',
                        style: TextStyle(
                          color: isMe ? onPrimary : theme.colorScheme.onSurface,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? onPrimary.withValues(alpha: 0.72)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  if (showStatus) ...[
                    const SizedBox(width: 4),
                    MessageStatusIcon(status: status, size: 14, isDark: true),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
