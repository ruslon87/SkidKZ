// lib/features/admin/screens/admin_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  String _safeLocation(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return '/';
    return router.routeInformationProvider.value.uri.path; // ← важно
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = _safeLocation(context);
    if (location.startsWith('/admin/moderation')) return 0;
    if (location.startsWith('/admin/users')) return 1;
    if (location.startsWith('/admin/finance')) return 2;
    return 0;
  }

  void _go(BuildContext context, String path) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    router.go(path);
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;

    if (router.canPop()) {
      router.pop();
      return;
    }

    // На корневых страницах админки — уходим на выбор роли
    router.go('/role-select');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                _go(context, '/admin/moderation');
                break;
              case 1:
                _go(context, '/admin/users');
                break;
              case 2:
                _go(context, '/admin/finance');
                break;
            }
          },
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
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments, color: Colors.red),
              label: 'Финансы',
            ),
          ],
        ),
      ),
    );
  }
}
