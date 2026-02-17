// lib/features/buyer/screens/buyer_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_bottom_nav.dart';

class BuyerRootShell extends StatefulWidget {
  final Widget child;

  const BuyerRootShell({super.key, required this.child});

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  DateTime? _lastBackPress;

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
    }
  }

  Future<void> _handleBack(int currentIndex) async {
    if (currentIndex != 0) {
      _goByIndex(0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Нажмите ещё раз, чтобы выйти'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final idx = _calcIndexFromLocation(path);

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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack(idx);
      },
      child: AppScaffold(
        appBar: const AppTopBar(
          title: 'SkidKZ',
          leading: SizedBox(width: 48),
        ),
        drawer: null,
        bottomNavigationBar: bottomNav,
        body: widget.child,
      ),
    );
  }
}
