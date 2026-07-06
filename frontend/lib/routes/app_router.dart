import 'package:go_router/go_router.dart';
import 'package:unichat/controllers/auth_controller.dart';
import 'package:unichat/views/login_view.dart';
import 'package:unichat/views/register_view.dart';
import 'package:unichat/views/chat_view.dart';
import 'package:unichat/views/contacts_view.dart';
import 'package:unichat/views/home_view.dart';
import 'package:unichat/views/notifications_view.dart';
import 'package:unichat/views/edit_profile_view.dart';
import 'package:unichat/views/profile_view.dart';
import 'package:unichat/views/shell_view.dart';

/// Cria o GoRouter com guards de autenticação e StatefulShellRoute.
GoRouter createRouter(AuthController authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Não autenticado tentando acessar rota protegida
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Já autenticado tentando acessar rota de auth
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // ─── Rotas de Autenticação ───
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),

      // ─── Shell com BottomNavigationBar (3 abas) ───
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellView(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Conversas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          // Branch 2: Contatos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (context, state) => const ContactsView(),
              ),
            ],
          ),
          // Branch 3: Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),

      // ─── Rotas fora do Shell (sem bottom nav) ───
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          final participantName = state.extra as String? ?? 'Chat';
          return ChatView(
            chatId: chatId,
            participantName: participantName,
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileView(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationsView(),
      ),
    ],
  );
}
