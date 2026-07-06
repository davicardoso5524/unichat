import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';
import 'package:unichat/controllers/auth_controller.dart';
import 'package:unichat/controllers/theme_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();
    final themeProvider = context.watch<ThemeController>();
    final profile = authProvider.profile;

    String initials = '';
    if (profile != null && profile.name.isNotEmpty) {
      final parts = profile.name.split(' ');
      initials = parts.length > 1
          ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
          : parts.first[0].toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil', style: AppTextStyles.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF8B83FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppTextStyles.display.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nome
            Text(
              profile?.name ?? 'Usuário',
              style: AppTextStyles.title.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              profile?.email ?? '',
              style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            // Badge de role
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile?.isProfessor == true ? 'Professor' : 'Aluno',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Opções
            ProfileTile(
              icon: Icons.edit_outlined,
              title: 'Editar perfil',
              onTap: () => context.push('/profile/edit'),
            ),
            ProfileTile(
              icon: Icons.dark_mode_outlined,
              title: 'Modo escuro',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            ProfileTile(
              icon: Icons.notifications_outlined,
              title: 'Notificações',
              onTap: () => context.push('/profile/notifications'),
            ),
            const SizedBox(height: 16),
            // Botão de logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.destructive),
                label: Text(
                  'Sair',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.destructive,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.destructive),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'UniChat v1.0 · Beta',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
