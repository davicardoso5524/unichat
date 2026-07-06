import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';
import 'package:unichat/widgets/widgets.dart';
import 'package:unichat/controllers/auth_controller.dart';
import 'package:unichat/controllers/home_controller.dart';
import 'package:unichat/models/models.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadChats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: context.read<HomeController>(),
        child: const _NewChatSheet(),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) {
      return '${time.day}/${time.month}';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'UniChat',
          style: AppTextStyles.title.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: AvatarWidget(
                name: authProvider.profile?.name ?? 'U',
                size: 36,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca local (filtra chats existentes)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar conversas...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Lista de chats
          Expanded(
            child: Consumer<HomeController>(
              builder: (context, homeProvider, _) {
                if (homeProvider.isLoading) {
                  return const LoadingWidget();
                }

                final filteredChats = homeProvider.chats.where((chat) {
                  if (_searchQuery.isEmpty) return true;
                  return chat.participantName
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();

                if (filteredChats.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Nenhuma conversa',
                    subtitle:
                        'Inicie uma nova conversa tocando no botão +',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => homeProvider.loadChats(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return ConversationCard(
                        name: chat.participantName,
                        lastMessage: chat.lastMessage,
                        time: _formatTime(chat.lastMessageTime),
                        unreadCount: 0,
                        avatarInitials: chat.participantName,
                        onTap: () => context.go(
                          '/chat/${chat.id}',
                          extra: chat.participantName,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// Bottom sheet para criar novo chat (buscar usuários).
class _NewChatSheet extends StatefulWidget {
  const _NewChatSheet();

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _searchController = TextEditingController();
  List<ProfileModel> _localResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isSearching = true);
    try {
      final homeProvider = context.read<HomeController>();
      await homeProvider.searchUsers('');
      if (mounted) {
        setState(() {
          _localResults = homeProvider.searchResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _filterUsers(String query) {
    final homeProvider = context.read<HomeController>();
    if (query.isEmpty) {
      setState(() => _localResults = homeProvider.searchResults);
    } else {
      final lower = query.toLowerCase();
      setState(() {
        _localResults = homeProvider.searchResults.where((p) {
          return p.name.toLowerCase().contains(lower) ||
              p.email.toLowerCase().contains(lower);
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createChat(ProfileModel profile) async {
    final homeProvider = context.read<HomeController>();
    final chatId = await homeProvider.createChat(profile.id);

    if (chatId != null && mounted) {
      Navigator.pop(context); // Fecha o bottom sheet
      context.go('/chat/$chatId', extra: profile.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Nova conversa',
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Busca de usuários
              TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou e-mail...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 16),
              // Lista de resultados
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _localResults.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum usuário encontrado',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _localResults.length,
                            itemBuilder: (context, index) {
                              final profile = _localResults[index];
                              return ListTile(
                                leading: AvatarWidget(
                                  name: profile.name,
                                  size: 44,
                                ),
                                title: Text(
                                  profile.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${profile.email} • ${profile.isProfessor ? 'Professor' : 'Aluno'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                trailing: profile.isProfessor
                                    ? const ProfessorBadge()
                                    : null,
                                onTap: () => _createChat(profile),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
