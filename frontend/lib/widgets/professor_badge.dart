import 'package:flutter/material.dart';

class ProfessorBadge extends StatelessWidget {
  const ProfessorBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final foreground = Theme.of(context).colorScheme.onSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Prof.',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
