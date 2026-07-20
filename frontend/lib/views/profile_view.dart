import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';
import 'package:unichat/controllers/auth_controller.dart';
import 'package:unichat/controllers/theme_controller.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarPerfil();
    });
  }

  Future<void> _carregarPerfil() async {
    final authController = context.read<AuthController>();
    if (authController.profile != null) {
      if (mounted) setState(() => _initialLoadDone = true);
      return;
    }
    await authController.carregarPerfil();
    if (mounted) {
      setState(() => _initialLoadDone = true);
    }
  }

  Future<void> _abrirEdicao() async {
    await context.push('/profile/edit');
    if (mounted) {
      await context.read<AuthController>().carregarPerfil();
    }
  }

  String _pegarIniciais(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final themeProvider = context.watch<ThemeController>();
    final theme = Theme.of(context);
    final profile = authController.profile;
    final initials = _pegarIniciais(profile?.name);

    return Scaffold(
      appBar: AppBar(title: Text('Perfil', style: AppTextStyles.title)),
      body: (!_initialLoadDone && profile == null)
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.brightness == Brightness.dark
                              ? AppColors.accentLight
                              : AppColors.primaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTextStyles.display.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile?.name ?? 'Usuário',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.email ?? '',
                    style: AppTextStyles.body.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.68,
                      ),
                    ),
                  ),
                  if (profile != null && profile.course.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.course,
                      style: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.68,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (profile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        profile.ehProfessor ? 'Professor' : 'Aluno',
                        style: AppTextStyles.caption.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  ProfileTile(
                    icon: Icons.edit_outlined,
                    title: 'Editar perfil',
                    onTap: _abrirEdicao,
                  ),
                  ProfileTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Modo escuro',
                    trailing: Switch(
                      value: themeProvider.estaEmModoEscuro,
                      onChanged: (_) => themeProvider.alternarTema(),
                      activeTrackColor: AppColors.primary.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  ProfileTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notificações',
                    onTap: () => context.push('/profile/notifications'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await authController.logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.destructive,
                      ),
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
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
