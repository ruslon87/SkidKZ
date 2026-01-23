import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // перехватываем системную кнопку Back
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Если есть куда возвращаться (например, был push на детальный экран) — попаем.
        if (context.canPop()) {
          context.pop();
          return;
        }

        // Иначе мы на корневых страницах админки — возвращаем на выбор роли.
        context.go('/role-select');
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: Colors.redAccent.withOpacity(0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.gavel_outlined),
              selectedIcon: Icon(Icons.gavel, color: Colors.red),
              label: 'Модерация',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: Colors.red),
              label: 'Пользователи',
            ),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin/moderation')) return 0;
    if (location.startsWith('/admin/users')) return 1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/moderation');
        break;
      case 1:
        context.go('/admin/users');
        break;
    }
  }
}
