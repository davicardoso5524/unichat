import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellView extends StatefulWidget {
  const ShellView({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onDestinationSelected,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.55),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Conversas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Contatos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
