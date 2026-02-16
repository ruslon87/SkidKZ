// lib/features/admin/screens/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastBackPress;

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

  String _rootPathForIndex(int index) {
    switch (index) {
      case 0:
        return '/admin/moderation';
      case 1:
        return '/admin/users';
      case 2:
        return '/admin/finance';
      default:
        return '/admin/moderation';
    }
  }

  bool _isRootRouteForTab(String path, int index) => path == _rootPathForIndex(index);

  Future<bool> _handleBack(int currentIndex, String currentPath) async {
    final scaffold = _scaffoldKey.currentState;

    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return true;
    }

    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return true;
    }

    if (!_isRootRouteForTab(currentPath, currentIndex)) {
      _go(context, _rootPathForIndex(currentIndex));
      return true;
    }

    if (currentIndex != 0) {
      _go(context, '/admin/moderation');
      return true;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Нажмите ещё раз, чтоы выйти'),
            duration: Duration(seconds: 2),
          ),
        );
      return true;
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final location = _safeLocation(context);
    final idx = _calculateSelectedIndex(context);

    return BackButtonListener(
      onBackButtonPressed: () => _handleBack(idx, location),
      child: AppScaffold(
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
      ),
    );
  }
}
