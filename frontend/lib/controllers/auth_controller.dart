import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unichat/models/models.dart';

/// Controller de autenticação (Supabase Auth + tabela profiles).
///
/// Concentra toda a lógica de login/registro/logout e o carregamento
/// do perfil do usuário logado. Antes ficava dividido em AuthService +
/// AuthController; agora está foldado em um único controller (MVC).
class AuthController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;

  AuthController() {
    _inicializar();
  }

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _client.auth.currentUser != null;
  String? get idUsuarioAtual => _client.auth.currentUser?.id;

  void _inicializar() {
    // Escuta mudanças de auth para atualizar o estado.
    _authSubscription = _client.auth.onAuthStateChange.listen((
      authState,
    ) async {
      if (authState.event == AuthChangeEvent.signedIn) {
        await _carregarPerfilInterno();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _profile = null;
      }
      notifyListeners();
    });

    // Se já está logado, carrega o profile.
    if (isAuthenticated) {
      _carregarPerfilInterno();
    }
  }

  // ─── Acesso a dados (profiles) ───

  Future<ProfileModel?> _buscarMeuPerfil() async {
    final userId = idUsuarioAtual;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(response);
  }

  Future<void> _carregarPerfilInterno() async {
    try {
      _profile = await _buscarMeuPerfil();
    } catch (e) {
      debugPrint('Erro ao carregar profile: $e');
    }
  }

  /// Tenta carregar o profile com retry (o trigger do Supabase pode
  /// levar alguns ms para criar a linha na tabela profiles).
  Future<void> _carregarPerfilComTentativas({int maxAttempts = 5}) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        _profile = await _buscarMeuPerfil();
        if (_profile != null) return;
      } catch (e) {
        debugPrint('Tentativa ${i + 1} de carregar profile falhou: $e');
      }
      await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
    }
  }

  /// Recarrega o profile do usuário (público, para uso após editar perfil).
  Future<void> carregarPerfil() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _buscarMeuPerfil();
      if (_profile == null) {
        // Retry caso o trigger do Supabase ainda não tenha criado o profile
        await _carregarPerfilComTentativas(maxAttempts: 3);
      }
    } catch (e) {
      debugPrint('Erro ao carregar profile (público): $e');
      // Tenta com retry em caso de erro
      await _carregarPerfilComTentativas(maxAttempts: 3);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Autenticação ───

  /// Login com email e senha.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      await _carregarPerfilInterno();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = _traduzirErroAuth(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erro ao fazer login. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registro com nome, email, senha, role (student/professor) e curso.
  Future<bool> register(
    String name,
    String email,
    String password,
    String role,
    String course,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role, 'course': course},
      );
      // Aguarda o trigger do Supabase criar o profile.
      await _carregarPerfilComTentativas();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = _traduzirErroAuth(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erro ao criar conta. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout.
  Future<void> logout() async {
    await _client.auth.signOut();
    _profile = null;
    _error = null;
    notifyListeners();
  }

  /// Traduz erros comuns do Supabase Auth para português.
  String _traduzirErroAuth(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (lower.contains('user already registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (lower.contains('password')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (lower.contains('email')) {
      return 'E-mail inválido.';
    }
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
