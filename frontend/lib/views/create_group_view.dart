import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unichat/controllers/group_controller.dart';
import 'package:unichat/controllers/home_controller.dart';
import 'package:unichat/models/models.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';

/// Tela de criação de grupo: nome, imagem e seleção de membros.
class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  Uint8List? _imageBytes;
  PlatformFile? _imageFile;
  final List<ProfileModel> _selectedMembers = [];
  List<ProfileModel> _contacts = [];
  List<ProfileModel> _filteredContacts = [];
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _carregarContatos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarContatos() async {
    final homeController = context.read<HomeController>();
    await homeController.buscarUsuarios('');
    setState(() {
      _contacts = homeController.searchResults;
      _filteredContacts = _contacts;
      _isLoadingContacts = false;
    });
  }

  void _filtrarContatos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        final lower = query.toLowerCase();
        _filteredContacts = _contacts.where((c) {
          return c.name.toLowerCase().contains(lower) ||
              c.email.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  void _alternarMembro(ProfileModel profile) {
    setState(() {
      final exists = _selectedMembers.any((m) => m.id == profile.id);
      if (exists) {
        _selectedMembers.removeWhere((m) => m.id == profile.id);
      } else {
        _selectedMembers.add(profile);
      }
    });
  }

  Future<void> _selecionarImagem() async {
    final groupController = context.read<GroupController>();
    final file = await groupController.selecionarImagemDoGrupo();
    if (file != null && file.bytes != null) {
      setState(() {
        _imageBytes = file.bytes;
        _imageFile = file;
      });
    }
  }

  Future<void> _criarGrupo() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome para o grupo')),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um membro')),
      );
      return;
    }

    final groupController = context.read<GroupController>();
    final chatId = await groupController.criarGrupo(
      name: name,
      memberIds: _selectedMembers.map((m) => m.id).toList(),
      imageBytes: _imageBytes,
      imageExtension: _imageFile?.extension,
    );

    if (chatId != null && mounted) {
      // Recarrega lista de chats
      context.read<HomeController>().carregarConversas();
      context.push('/chat/$chatId', extra: {'name': name, 'isGroup': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Criar Grupo'),
        actions: [
          Consumer<GroupController>(
            builder: (context, controller, _) {
              return TextButton(
                onPressed: controller.isLoading ? null : _criarGrupo,
                child: controller.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Criar',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Header: Imagem + Nome ───
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Imagem do grupo
                GestureDetector(
                  onTap: _selecionarImagem,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      image: _imageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_imageBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageBytes == null
                        ? Icon(
                            Icons.camera_alt_outlined,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            size: 28,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Nome do grupo
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Nome do grupo',
                      border: UnderlineInputBorder(),
                    ),
                    style: AppTextStyles.body.copyWith(fontSize: 18),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ],
            ),
          ),

          // ─── Membros selecionados ───
          if (_selectedMembers.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedMembers.length,
                itemBuilder: (context, index) {
                  final member = _selectedMembers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            AvatarWidget(name: member.name, size: 48),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _alternarMembro(member),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppColors.destructive,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 56,
                          child: Text(
                            member.name.split(' ').first,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // ─── Divisor ───
          const Divider(height: 1),

          // ─── Busca de contatos ───
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarContatos,
              decoration: InputDecoration(
                hintText: 'Buscar contatos...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),

          // ─── Lista de contatos ───
          Expanded(
            child: _isLoadingContacts
                ? const LoadingWidget()
                : _filteredContacts.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Nenhum contato encontrado',
                    subtitle: '',
                  )
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final isSelected = _selectedMembers.any(
                        (m) => m.id == contact.id,
                      );

                      return ListTile(
                        leading: AvatarWidget(name: contact.name, size: 44),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                contact.name,
                                style: AppTextStyles.body,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (contact.ehProfessor) ...[
                              const SizedBox(width: 8),
                              const ProfessorBadge(),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          contact.course.isNotEmpty
                              ? '${contact.course} · ${contact.email}'
                              : contact.email,
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _alternarMembro(contact),
                          activeColor: AppColors.primary,
                          shape: const CircleBorder(),
                        ),
                        onTap: () => _alternarMembro(contact),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
