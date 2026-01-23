import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/repositories/mock_database.dart';

class BuyerShell extends ConsumerWidget {
  final Widget child;

  const BuyerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        // 1) Если есть что "попнуть" (детальные экраны) — возвращаемся назад
        if (context.canPop()) {
          context.pop();
          return;
        }

        // 2) Если мы на корневых экранах покупателя — выходим на выбор роли
        // Важно: делаем logout, иначе redirect вернёт обратно в /buyer/home
        ref.read(authProvider.notifier).logout();
        context.go('/role-select');
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppTheme.secondary,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view, color: AppTheme.primary),
              label: 'Каталог',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primary),
              label: 'Заказы',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primary),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/buyer/home')) return 0;
    if (location.startsWith('/buyer/orders')) return 1;
    if (location.startsWith('/buyer/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/buyer/home');
        break;
      case 1:
        context.go('/buyer/orders');
        break;
      case 2:
        // если профиля нет — оставь пустым или добавь маршрут
        // context.go('/buyer/profile');
        break;
    }
  }
}
