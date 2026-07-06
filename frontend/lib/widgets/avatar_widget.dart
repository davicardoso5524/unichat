import 'package:flutter/material.dart';
import 'package:unichat/theme/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final bool isOnline;

  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 40,
    this.isOnline = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get _backgroundColor {
    final hash = name.hashCode;
    final colors = [
      AppColors.primary,
      AppColors.accent,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: _backgroundColor.withValues(alpha: 0.15),
          child: Text(
            _initials,
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w600,
              color: _backgroundColor,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
