import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:unichat/config/supabase_config.dart';
import 'package:unichat/models/models.dart';

/// Controller para operações de grupo.
class GroupController extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  bool _isLoading = false;
  String? _error;
  List<ProfileModel> _members = [];
  ChatModel? _groupInfo;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProfileModel> get members => _members;
  ChatModel? get groupInfo => _groupInfo;

  String get _idUsuarioAtual => _client.auth.currentUser!.id;

  /// Verifica se o usuário atual é o dono do grupo.
  bool get ehDono => _groupInfo?.ownerId == _idUsuarioAtual;

  // ─── Criação de Grupo ───

  /// Cria um novo grupo e retorna o chat_id.
  Future<int?> criarGrupo({
    required String name,
    required List<String> memberIds,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? imageUrl;

      // Upload da imagem do grupo se fornecida
      if (imageBytes != null) {
        imageUrl = await _enviarImagemDoGrupo(
          imageBytes,
          imageExtension ?? 'jpg',
        );
      }

      // Criar grupo via RPC
      final chatId = await _client.rpc(
        'create_group',
        params: {
          'group_name': name,
          'group_image_url': imageUrl,
          'member_ids': memberIds,
        },
      );

      _isLoading = false;
      notifyListeners();
      return chatId as int;
    } catch (e) {
      _error = 'Erro ao criar grupo.';
      debugPrint('Erro ao criar grupo: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Faz upload de imagem para o grupo e retorna a URL pública.
  /// Aceita bytes diretamente (funciona em web e mobile).
  Future<String?> _enviarImagemDoGrupo(
    Uint8List bytes,
    String extension,
  ) async {
    try {
      final fileName = 'group_${_uuid.v4()}.$extension';
      final storagePath = '$_idUsuarioAtual/$fileName';
      final bucket = _client.storage.from(SupabaseConfig.uploadsBucket);

      await bucket.uploadBinary(storagePath, bytes);
      return bucket.getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Erro ao fazer upload da imagem do grupo: $e');
      return null;
    }
  }

  /// Seleciona uma imagem para o grupo.
  /// Retorna os bytes e extensão do arquivo selecionado.
  Future<PlatformFile?> selecionarImagemDoGrupo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
    }
    return null;
  }

  // ─── Detalhes do Grupo ───

  /// Carrega informações do grupo e seus membros.
  Future<void> carregarDetalhesDoGrupo(int chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Buscar info do chat/grupo
      final chatData = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .single();

      _groupInfo = ChatModel.fromJson(chatData);

      // Buscar membros com perfil
      final participantsData = await _client
          .from('chat_participants')
          .select(
            'user_id, role, profiles(id, name, email, role, course, avatar_url)',
          )
          .eq('chat_id', chatId);

      _members = participantsData.map((p) {
        final profile = p['profiles'] as Map<String, dynamic>;
        return ProfileModel.fromJson(
          profile,
        ).copyWith(groupRole: p['role'] as String?);
      }).toList();

      // Dono primeiro na lista
      _members.sort((a, b) {
        if (a.id == _groupInfo?.ownerId) return -1;
        if (b.id == _groupInfo?.ownerId) return 1;
        return a.name.compareTo(b.name);
      });
    } catch (e) {
      _error = 'Erro ao carregar detalhes do grupo.';
      debugPrint('Erro ao carregar grupo: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Gerenciamento de Membros ───

  /// Adiciona um membro ao grupo.
  Future<bool> adicionarMembro(int chatId, String userId) async {
    try {
      await _client.rpc(
        'add_group_member',
        params: {'p_chat_id': chatId, 'p_user_id': userId},
      );
      await carregarDetalhesDoGrupo(chatId);
      return true;
    } catch (e) {
      _error = 'Erro ao adicionar membro.';
      debugPrint('Erro ao adicionar membro: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove um membro do grupo (apenas o dono pode).
  Future<bool> removerMembro(int chatId, String userId) async {
    try {
      await _client.rpc(
        'remove_group_member',
        params: {'p_chat_id': chatId, 'p_user_id': userId},
      );
      await carregarDetalhesDoGrupo(chatId);
      return true;
    } catch (e) {
      _error = 'Erro ao remover membro.';
      debugPrint('Erro ao remover membro: $e');
      notifyListeners();
      return false;
    }
  }

  // ─── Edição do Grupo ───

  /// Atualiza nome e/ou imagem do grupo.
  Future<bool> atualizarGrupo(
    int chatId, {
    String? name,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    try {
      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await _enviarImagemDoGrupo(
          imageBytes,
          imageExtension ?? 'jpg',
        );
      }

      await _client.rpc(
        'update_group',
        params: {
          'p_chat_id': chatId,
          'p_group_name': name,
          'p_group_image_url': imageUrl,
        },
      );

      await carregarDetalhesDoGrupo(chatId);
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar grupo.';
      debugPrint('Erro ao atualizar grupo: $e');
      notifyListeners();
      return false;
    }
  }

  // ─── Mensagens Fixadas ───

  /// Fixa uma mensagem com duração (24 = 24h, 168 = 7 dias).
  Future<bool> fixarMensagem(
    int chatId,
    int messageId, {
    int hours = 24,
  }) async {
    try {
      await _client.rpc(
        'pin_message',
        params: {
          'p_chat_id': chatId,
          'p_message_id': messageId,
          'p_duration_hours': hours,
        },
      );
      return true;
    } catch (e) {
      _error = 'Erro ao fixar mensagem.';
      debugPrint('Erro ao fixar mensagem: $e');
      notifyListeners();
      return false;
    }
  }

  /// Desafixa uma mensagem.
  Future<bool> desafixarMensagem(int chatId, int messageId) async {
    try {
      await _client.rpc(
        'unpin_message',
        params: {'p_chat_id': chatId, 'p_message_id': messageId},
      );
      return true;
    } catch (e) {
      _error = 'Erro ao desafixar mensagem.';
      debugPrint('Erro ao desafixar mensagem: $e');
      notifyListeners();
      return false;
    }
  }

  /// Busca mensagens fixadas ativas de um chat.
  Future<List<PinnedMessageModel>> buscarMensagensFixadas(int chatId) async {
    try {
      final data = await _client
          .from('pinned_messages')
          .select(
            '*, messages(id, content, sender_id, created_at, profiles(name, role))',
          )
          .eq('chat_id', chatId)
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('pinned_at', ascending: false);

      return data.map((json) => PinnedMessageModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar mensagens fixadas: $e');
      return [];
    }
  }

  void limparErro() {
    _error = null;
    notifyListeners();
  }
}
