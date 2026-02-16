// lib/features/buyer/screens/buyer_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_bottom_nav.dart';
import 'package:skidkz/core/widgets/app_main_drawer.dart';

class BuyerShellScope extends InheritedWidget {
  final VoidCallback openDrawer;

  const BuyerShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static BuyerShellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BuyerShellScope>()!;

  @override
  bool updateShouldNotify(BuyerShellScope oldWidget) => false;
}

class BuyerRootShell extends StatefulWidget {
  final Widget child;

  const BuyerRootShell({super.key, required this.child});

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPress;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  int _calcIndexFromLocation(String location) {
    if (location.startsWith('/buyer/home')) return 0;
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0;
  }

  void _goByIndex(int i) {
    switch (i) {
      case 0:
        context.go('/buyer/home');
        break;
      case 1:
        context.go('/buyer/catalog');
        break;
      case 2:
        context.go('/buyer/favorites');
        break;
      case 3:
        context.go('/buyer/cart');
        break;
      case 4:
        context.go('/buyer/profile');
        break;
      default:
        context.go('/buyer/home');
    }
  }

  Future<bool> _handleBack(int currentIndex) async {
    final scaffold = _scaffoldKey.currentState;

    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return false;
    }

    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return false;
    }

    if (currentIndex != 0) {
      _goByIndex(0);
      return false;
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
      return false;
    }

    SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _calcIndexFromLocation(location);

    final bottomNav = AppBottomNav(
      currentIndex: idx,
      onTap: _goByIndex,
      items: const [
        AppNavItem(icon: Icons.home_rounded, label: 'Главная'),
        AppNavItem(icon: Icons.grid_view_rounded, label: 'Каталог'),
        AppNavItem(icon: Icons.favorite_rounded, label: 'Избранное'),
        AppNavItem(icon: Icons.shopping_cart_rounded, label: 'Корзина'),
        AppNavItem(icon: Icons.person_rounded, label: 'Профиль'),
      ],
    );

    return WillPopScope(
      onWillPop: () => _handleBack(idx),
      child: BuyerShellScope(
        openDrawer: _openDrawer,
        child: AppScaffold(
          scaffoldKey: _scaffoldKey,
          appBar: AppTopBar(
            title: 'SkidKZ',
            onMenu: _openDrawer,
          ),
          drawer: const AppMainDrawer(),
          bottomNavigationBar: bottomNav,
          body: widget.child,
        ),
      ),
    );
  }
}
