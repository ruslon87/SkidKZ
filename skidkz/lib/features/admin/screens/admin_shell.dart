// lib/features/admin/screens/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_main_drawer.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  String _safeLocation(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return '/';
    return router.routeInformationProvider.value.uri.path;
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

  @override
  Widget build(BuildContext context) {
    final idx = _calculateSelectedIndex(context);

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: AppTopBar(
        title: 'Админка',
        onMenu: _openDrawer,
      ),
      drawer: const AppMainDrawer(),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
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
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Модерация',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Пользователи',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Финансы',
          ),
        ],
      ),
    );
  }
}
