// lib/features/wanghong/screens/wanghong_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/features/notifications/screens/notifications_screen.dart';

class WanghongShell extends StatelessWidget {
  final Widget child;

  const WanghongShell({super.key, required this.child});

  String _safeLocation(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return '/';
    return router.routeInformationProvider.value.uri.path;
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = _safeLocation(context);
    if (location.startsWith('/wanghong/home')) return 0;
    if (location.startsWith('/wanghong/deals')) return 1;
    if (location.startsWith('/wanghong/wallet')) return 2;
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SkidKZ Партнёр',
          style: TextStyle(
            color: Colors.black87,
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
                  color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              _go(context, '/wanghong/home');
              break;
            case 1:
              _go(context, '/wanghong/deals');
              break;
            case 2:
              _go(context, '/wanghong/wallet');
              break;
          }
        },
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: Colors.purple.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.purple),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer, color: Colors.purple),
            label: 'Сделки',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: Colors.purple),
            label: 'Кошелек',
          ),
        ],
      ),
    );
  }
}
