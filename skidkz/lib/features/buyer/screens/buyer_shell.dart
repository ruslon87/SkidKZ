// lib/features/buyer/screens/buyer_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_drawer.dart';
import 'package:skidkz/core/widgets/app_bottom_nav.dart';

/// Скоуп, чтобы дочерние экраны могли открыть drawer
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

/// ВАЖНО: имя класса должно совпадать с router: BuyerRootShell(child: child)
class BuyerRootShell extends StatefulWidget {
  final Widget child;

  const BuyerRootShell({super.key, required this.child});

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  int _calcIndexFromLocation(String location) {
    if (location.startsWith('/buyer/home')) return 0;
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;

    // orders не в bottom nav (обычно через drawer), но если хочешь — можно добавить вкладку
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

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _calcIndexFromLocation(location);

    final drawer = AppDrawer(
      headerTitle: 'SkidKZ',
      headerSubtitle: 'Покупатель',
      items: [
        AppDrawerItem(
          icon: Icons.home_outlined,
          title: 'Главная',
          onTap: () => context.go('/buyer/home'),
        ),
        AppDrawerItem(
          icon: Icons.grid_view_rounded,
          title: 'Каталог',
          onTap: () => context.go('/buyer/catalog'),
        ),
        AppDrawerItem(
          icon: Icons.favorite_border_rounded,
          title: 'Избранное',
          onTap: () => context.go('/buyer/favorites'),
        ),
        AppDrawerItem(
          icon: Icons.shopping_cart_outlined,
          title: 'Корзина',
          onTap: () => context.go('/buyer/cart'),
        ),
        AppDrawerItem(
          icon: Icons.receipt_long_outlined,
          title: 'Заказы',
          onTap: () => context.go('/buyer/orders'),
        ),
        AppDrawerItem(
          icon: Icons.person_outline,
          title: 'Профиль',
          onTap: () => context.go('/buyer/profile'),
        ),
      ],
    );

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

    return BuyerShellScope(
      openDrawer: _openDrawer,
      child: AppScaffold(
        scaffoldKey: _scaffoldKey,
        appBar: AppTopBar(
          title: 'SkidKZ',
          onMenu: _openDrawer,
        ),
        drawer: drawer,
        bottomNavigationBar: bottomNav,
        body: widget.child,
      ),
    );
  }
}
