import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';
import 'package:unichat/controllers/home_controller.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().buscarUsuarios('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Contatos', style: AppTextStyles.title)),
      body: Column(
        children: [
          _montarBarraBusca(theme),
          Expanded(
            child: Consumer<HomeController>(
              builder: (context, homeProvider, child) {
                if (homeProvider.isSearching) {
                  return const Center(child: LoadingWidget());
                }

                final results = homeProvider.searchResults;

                if (results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Nenhum contato encontrado',
                    subtitle: 'Tente buscar por outro nome ou email',
                  );
                }

                final professors = results
                    .where((user) => user.ehProfessor)
                    .toList();
                final students = results
                    .where((user) => !user.ehProfessor)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (professors.isNotEmpty) ...[
                      _montarTituloSecao('Professores', theme),
                      ...professors.map(
                        (profile) =>
                            _montarContato(profile, homeProvider, theme),
                      ),
                    ],
                    if (students.isNotEmpty) ...[
                      _montarTituloSecao('Alunos', theme),
                      ...students.map(
                        (profile) =>
                            _montarContato(profile, homeProvider, theme),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _montarBarraBusca(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<HomeController>().buscarUsuarios(value);
        },
        decoration: InputDecoration(
          hintText: 'Buscar contatos...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _montarTituloSecao(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _montarContato(
    dynamic profile,
    HomeController homeProvider,
    ThemeData theme,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: AvatarWidget(name: profile.name, size: 44),
      title: Row(
        children: [
          Flexible(
            child: Text(
              profile.name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (profile.ehProfessor) ...[
            const SizedBox(width: 8),
            const ProfessorBadge(),
          ],
        ],
      ),
      subtitle: Text(
        profile.course.isNotEmpty
            ? '${profile.course} · ${profile.email}'
            : profile.email,
        style: AppTextStyles.caption.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () async {
        final chatId = await homeProvider.criarConversa(profile.id);
        if (mounted && chatId != null) {
          homeProvider.carregarConversas();
          context.push(
            '/chat/$chatId',
            extra: {'name': profile.name, 'isGroup': false},
          );
        }
      },
    );
  }
}
