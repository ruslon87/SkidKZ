// lib/features/wanghong/screens/wanghong_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_main_drawer.dart';

class WanghongShell extends StatefulWidget {
  final Widget child;
  const WanghongShell({super.key, required this.child});

  @override
  State<WanghongShell> createState() => _WanghongShellState();
}

class _WanghongShellState extends State<WanghongShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

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
    final idx = _calculateSelectedIndex(context);

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: AppTopBar(
        title: 'Ванхун',
        onMenu: _openDrawer,
      ),
      drawer: const AppMainDrawer(),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
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
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Сделки',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Кошелёк',
          ),
        ],
      ),
    );
  }
}
