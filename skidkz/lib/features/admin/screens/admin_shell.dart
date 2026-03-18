// lib/features/admin/screens/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/features/notifications/screens/notifications_screen.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/admin/moderation')) {
      currentIndex = 1;
    } else if (location.startsWith('/admin/users')) {
      currentIndex = 2;
    } else if (location.startsWith('/admin/finance')) {
      currentIndex = 3;
    } else if (location.startsWith('/admin/settings')) {
      currentIndex = 4;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'SkidKZ Админ',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          NotificationBadge(
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
              icon: const Icon(Icons.notifications_outlined,
                  color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/admin/home'); break;
            case 1: context.go('/admin/moderation'); break;
            case 2: context.go('/admin/users'); break;
            case 3: context.go('/admin/finance'); break;
            case 4: context.go('/admin/settings'); break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified_rounded),
            label: 'Модерация',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Пользователи',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Финансы',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
