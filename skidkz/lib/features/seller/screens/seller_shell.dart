// lib/features/seller/screens/seller_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_main_drawer.dart';

class SellerShell extends StatefulWidget {
  final Widget child;
  const SellerShell({super.key, required this.child});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
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
    if (location.startsWith('/seller/products')) return 0;
    if (location.startsWith('/seller/orders')) return 1;
    return 0;
  }

  void _go(BuildContext context, String path) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    router.go(path);
  }

  Future<bool> _handleBack(int currentIndex) async {
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

    if (currentIndex != 0) {
      _go(context, '/seller/products');
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
            content: Text('Нажмите ещё раз, чтобы выйти'),
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
    final idx = _calculateSelectedIndex(context);

    return BackButtonListener(
      onBackButtonPressed: () => _handleBack(idx),
      child: AppScaffold(
        scaffoldKey: _scaffoldKey,
        appBar: AppTopBar(
          title: 'Магазин',
          onMenu: _openDrawer,
        ),
        drawer: const AppMainDrawer(),
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                _go(context, '/seller/products');
                break;
              case 1:
                _go(context, '/seller/orders');
                break;
            }
          },
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Товары',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Заказы',
            ),
          ],
        ),
      ),
    );
  }
}
