import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class BuyerShell extends StatelessWidget {
  final Widget child;

  const BuyerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Если был push на детальный экран — возвращаемся назад
        if (context.canPop()) {
          context.pop();
          return;
        }

        // Если мы на корневых страницах покупателя — уходим на выбор роли
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
        // если профиля нет — можно оставить пустым или тоже вести на /buyer/profile
        // context.go('/buyer/profile');
        break;
    }
  }
}
