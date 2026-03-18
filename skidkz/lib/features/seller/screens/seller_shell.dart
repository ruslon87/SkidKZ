// lib/features/seller/screens/seller_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SellerShell extends StatelessWidget {
  final Widget child;

  const SellerShell({super.key, required this.child});

  String _safeLocation(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return '/';
    return router.routeInformationProvider.value.uri.path;
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = _safeLocation(context);
    if (location.startsWith('/seller/home')) return 0;
    if (location.startsWith('/seller/products')) return 1;
    if (location.startsWith('/seller/orders')) return 2;
    return 0;
  }

  void _go(BuildContext context, String path) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    router.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              _go(context, '/seller/home');
              break;
            case 1:
              _go(context, '/seller/products');
              break;
            case 2:
              _go(context, '/seller/orders');
              break;
          }
        },
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: Colors.orangeAccent.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.orange),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Colors.orange),
            label: 'Товары',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: Colors.orange),
            label: 'Заказы',
          ),
        ],
      ),
    );
  }
}
