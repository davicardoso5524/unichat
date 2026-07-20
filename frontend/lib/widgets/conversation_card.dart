import 'package:flutter/material.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/widgets/avatar_widget.dart';

class ConversationCard extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String avatarInitials;
  final bool isGroup;
  final String? groupImageUrl;
  final VoidCallback? onTap;

  const ConversationCard({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    required this.avatarInitials,
    this.isGroup = false,
    this.groupImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: isGroup
          ? Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHighest,
                image: groupImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(groupImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: groupImageUrl == null
                  ? const Icon(Icons.group, size: 24, color: Colors.grey)
                  : null,
            )
          : AvatarWidget(name: name, size: 48),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: theme.colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        lastMessage,
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: unreadCount > 0
                  ? AppColors.accent
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: theme.colorScheme.onSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
