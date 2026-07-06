import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unichat/models/models.dart';

/// Controller da tela de perfil (leitura e atualização do profile).
class ProfileController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Carrega o profile do usuário atual.
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId != null) {
        final response =
            await _client.from('profiles').select().eq('id', userId).single();
        _profile = ProfileModel.fromJson(response);
      }
    } catch (e) {
      _error = 'Erro ao carregar perfil.';
      debugPrint('Erro ao carregar perfil: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Atualiza o nome do perfil.
  Future<bool> updateName(String name) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      await _client.from('profiles').update({'name': name}).eq('id', userId);
      await loadProfile();
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar perfil.';
      notifyListeners();
      return false;
    }
  }
}
