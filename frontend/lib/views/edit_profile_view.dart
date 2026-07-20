import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/controllers/auth_controller.dart';
import 'package:unichat/controllers/profile_controller.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  String _role = '';
  String _course = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthController>().profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _role = profile?.role ?? '';
    _course = profile?.course ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome não pode estar vazio')),
      );
      return;
    }

    final profileController = context.read<ProfileController>();
    final authController = context.read<AuthController>();
    setState(() => _isLoading = true);

    try {
      final success = await profileController.atualizarNome(name);
      await authController.carregarPerfil();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil atualizado com sucesso!')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao atualizar perfil.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar perfil: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            _montarAvatar(),
            const SizedBox(height: 32),

            _montarCampoNome(),
            const SizedBox(height: 16),

            _montarCampoEmail(),
            const SizedBox(height: 16),

            _montarSeloPerfil(),
            const SizedBox(height: 8),
            _montarSeloCurso(),
            const SizedBox(height: 40),

            _montarBotaoSalvar(),
          ],
        ),
      ),
    );
  }

  Widget _montarAvatar() {
    final theme = Theme.of(context);

    return Center(
      child: Stack(
        children: [
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
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: 48,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.camera_alt,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _montarCampoNome() {
    final theme = Theme.of(context);

    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nome',
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _montarCampoEmail() {
    return TextField(
      controller: _emailController,
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: 'Email',
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _montarSeloPerfil() {
    final theme = Theme.of(context);
    final displayRole = _role.toLowerCase() == 'student'
        ? 'Aluno'
        : 'Professor';

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(displayRole),
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _montarSeloCurso() {
    if (_course.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: const Icon(Icons.menu_book_outlined, size: 16),
        label: Text(_course),
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        labelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _montarBotaoSalvar() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _salvarAlteracoes,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Salvar alterações', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
