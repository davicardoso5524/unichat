import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unichat/config/app_constants.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';
import 'package:unichat/controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _userType = 'student';
  String? _selectedCourse;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fazerCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthController>();
    final success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _userType,
      _selectedCourse!,
    );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'Criar conta',
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Junte-se à comunidade UniChat',
                    style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  // Nome
                  CustomTextField(
                    controller: _nameController,
                    hint: 'Nome completo',
                    prefixIcon: const Icon(Icons.person_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu nome';
                      }
                      if (value.trim().length < 3) {
                        return 'Nome deve ter pelo menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Email
                  CustomTextField(
                    controller: _emailController,
                    hint: 'E-mail institucional',
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      if (!value.contains('@')) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Senha
                  CustomTextField(
                    controller: _passwordController,
                    hint: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe uma senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Confirmar senha
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirmar senha',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    obscure: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirme sua senha';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCourse,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Selecione seu curso',
                      prefixIcon: const Icon(Icons.menu_book_outlined),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: AppConstants.cursosAcademicos
                        .map(
                          (course) => DropdownMenuItem<String>(
                            value: course,
                            child: Text(
                              course,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCourse = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione seu curso';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Tipo de usuário
                  Text('Você é:', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'student',
                        label: Text('Aluno'),
                        icon: Icon(Icons.school_outlined),
                      ),
                      ButtonSegment(
                        value: 'professor',
                        label: Text('Professor'),
                        icon: Icon(Icons.workspace_premium_outlined),
                      ),
                    ],
                    selected: {_userType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _userType = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Erro
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      if (auth.error != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            auth.error!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.destructive,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Botão de registro
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Criar conta',
                          onPressed: auth.isLoading ? null : _fazerCadastro,
                          isLoading: auth.isLoading,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Link para login
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Já tem conta? ',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey[600],
                        ),
                        children: [
                          TextSpan(
                            text: 'Entrar',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
