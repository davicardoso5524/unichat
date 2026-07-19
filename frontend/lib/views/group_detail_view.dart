import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unichat/controllers/group_controller.dart';
import 'package:unichat/controllers/home_controller.dart';
import 'package:unichat/models/models.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';

/// Tela de detalhes do grupo: edição de nome/imagem, lista de membros,
/// e ações do dono (adicionar/expulsar membros).
class GroupDetailView extends StatefulWidget {
  final int chatId;

  const GroupDetailView({super.key, required this.chatId});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupController>().carregarDetalhesDoGrupo(widget.chatId);
    });
  }

  Future<void> _editarNomeDoGrupo() async {
    final groupController = context.read<GroupController>();
    final currentName = groupController.groupInfo?.groupName ?? '';
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nome do grupo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Digite o novo nome'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      await groupController.atualizarGrupo(widget.chatId, name: newName);
    }
  }

  Future<void> _editarImagemDoGrupo() async {
    final groupController = context.read<GroupController>();
    final file = await groupController.selecionarImagemDoGrupo();
    if (file != null && file.bytes != null) {
      await groupController.atualizarGrupo(
        widget.chatId,
        imageBytes: file.bytes,
        imageExtension: file.extension,
      );
    }
  }

  Future<void> _adicionarMembro() async {
    final groupController = context.read<GroupController>();
    final homeController = context.read<HomeController>();

    // Buscar todos os contatos
    await homeController.buscarUsuarios('');
    final allContacts = homeController.searchResults;

    // Filtrar quem já é membro
    final currentMemberIds = groupController.members.map((m) => m.id).toSet();
    final available = allContacts
        .where((c) => !currentMemberIds.contains(c.id))
        .toList();

    if (!mounted) return;

    final selected = await showModalBottomSheet<ProfileModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Adicionar membro',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: available.isEmpty
                  ? const Center(child: Text('Nenhum contato disponível'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: available.length,
                      itemBuilder: (context, index) {
                        final contact = available[index];
                        return ListTile(
                          leading: AvatarWidget(name: contact.name, size: 44),
                          title: Text(contact.name),
                          subtitle: Text(contact.email),
                          onTap: () => Navigator.pop(context, contact),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await groupController.adicionarMembro(widget.chatId, selected.id);
    }
  }

  Future<void> _removerMembro(ProfileModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover membro'),
        content: Text('Deseja remover ${member.name} do grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<GroupController>().removerMembro(
        widget.chatId,
        member.id,
      );
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
        title: const Text('Detalhes do Grupo'),
      ),
      body: Consumer<GroupController>(
        builder: (context, groupController, _) {
          if (groupController.isLoading) {
            return const LoadingWidget();
          }

          final group = groupController.groupInfo;
          if (group == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Erro ao carregar grupo',
              subtitle: '',
            );
          }

          final ehDono = groupController.ehDono;

          return ListView(
            children: [
              // ─── Header do grupo ───
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    // Imagem do grupo
                    GestureDetector(
                      onTap: ehDono ? _editarImagemDoGrupo : null,
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surfaceContainerHighest,
                              image: group.groupImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(group.groupImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: group.groupImageUrl == null
                                ? const Icon(
                                    Icons.group,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          if (ehDono)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Nome do grupo
                    GestureDetector(
                      onTap: ehDono ? _editarNomeDoGrupo : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            group.groupName ?? 'Grupo',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (ehDono) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${groupController.members.length} membros',
                      style: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ─── Seção: Membros ───
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Membros',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (ehDono)
                      TextButton.icon(
                        onPressed: _adicionarMembro,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Adicionar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),

              // Lista de membros
              ...groupController.members.map((member) {
                final ehDonoMembro = member.ehDonoDoGrupo;

                return ListTile(
                  leading: AvatarWidget(name: member.name, size: 44),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          style: AppTextStyles.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ehDonoMembro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Dono',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    member.email,
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: ehDono && !ehDonoMembro
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.destructive,
                          onPressed: () => _removerMembro(member),
                          tooltip: 'Remover do grupo',
                        )
                      : null,
                );
              }),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
