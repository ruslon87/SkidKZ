// lib/features/seller/screens/seller_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_drawer.dart';
import 'package:skidkz/core/widgets/app_bottom_nav.dart';

class SellerShellScope extends InheritedWidget {
  final VoidCallback openDrawer;

  const SellerShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static SellerShellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SellerShellScope>()!;

  @override
  bool updateShouldNotify(SellerShellScope oldWidget) => false;
}

class SellerShell extends StatefulWidget {
  final Widget child;

  const SellerShell({super.key, required this.child});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  int _calcIndexFromLocation(String location) {
    if (location.startsWith('/seller/products')) return 0; // включая /add
    if (location.startsWith('/seller/orders')) return 1;
    return 0;
  }

  void _goByIndex(int i) {
    switch (i) {
      case 0:
        context.go('/seller/products');
        break;
      case 1:
        context.go('/seller/orders');
        break;
      default:
        context.go('/seller/products');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _calcIndexFromLocation(location);

    final drawer = AppDrawer(
      headerTitle: 'SkidKZ',
      headerSubtitle: 'Продавец',
      items: [
        AppDrawerItem(
          icon: Icons.inventory_2_outlined,
          title: 'Товары',
          onTap: () => context.go('/seller/products'),
        ),
        AppDrawerItem(
          icon: Icons.add_box_outlined,
          title: 'Добавить товар',
          onTap: () => context.go('/seller/products/add'),
        ),
        AppDrawerItem(
          icon: Icons.list_alt_outlined,
          title: 'Заказы',
          onTap: () => context.go('/seller/orders'),
        ),
      ],
      bottomItems: [
        AppDrawerItem(
          icon: Icons.info_outline,
          title: 'Инфо для продавца',
          onTap: () => context.go('/info/seller'),
        ),
        AppDrawerItem(
          icon: Icons.switch_account_outlined,
          title: 'Сменить роль',
          onTap: () => context.go('/role-select'),
        ),
        AppDrawerItem(
          icon: Icons.home_outlined,
          title: 'В витрину (покупатель)',
          onTap: () => context.go('/buyer/home'),
        ),
      ],
    );

    final bottomNav = AppBottomNav(
      currentIndex: idx,
      onTap: _goByIndex,
      items: const [
        AppNavItem(icon: Icons.inventory_2_rounded, label: 'Товары'),
        AppNavItem(icon: Icons.list_alt_rounded, label: 'Заказы'),
      ],
    );

    return SellerShellScope(
      openDrawer: _openDrawer,
      child: AppScaffold(
        scaffoldKey: _scaffoldKey,
        appBar: AppTopBar(
          title: 'Панель продавца',
          onMenu: _openDrawer,
          actions: [
            IconButton(
              tooltip: 'Добавить',
              onPressed: () => context.go('/seller/products/add'),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        drawer: drawer,
        bottomNavigationBar: bottomNav,
        body: widget.child,
      ),
    );
  }
}
