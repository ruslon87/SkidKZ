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

class BuyerShell extends StatefulWidget {
  final Widget child;

  const BuyerShell({super.key, required this.child});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  int _calcIndexFromLocation(String location) {
    // Подстрой под свои реальные маршруты buyer
    if (location.startsWith('/buyer/home')) return 0;
    if (location.startsWith('/buyer/orders')) return 1;
    if (location.startsWith('/buyer/profile')) return 2;
    return 0;
  }

  void _goByIndex(int i) {
    // Подстрой под свои реальные маршруты buyer
    switch (i) {
      case 0:
        context.go('/buyer/home');
        break;
      case 1:
        context.go('/buyer/orders');
        break;
      case 2:
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
          icon: Icons.storefront_outlined,
          title: 'Витрина',
          onTap: () => context.go('/buyer/home'),
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
      bottomItems: [
        AppDrawerItem(
          icon: Icons.info_outline,
          title: 'О приложении',
          onTap: () => context.go('/info'),
        ),
      ],
    );

    final bottomNav = AppBottomNav(
      currentIndex: idx,
      onTap: _goByIndex,
      items: const [
        AppNavItem(icon: Icons.home_rounded, label: 'Главная'),
        AppNavItem(icon: Icons.receipt_long_rounded, label: 'Заказы'),
        AppNavItem(icon: Icons.person_rounded, label: 'Профиль'),
      ],
    );

    return BuyerShellScope(
      openDrawer: _openDrawer,
      child: AppScaffold(
        key: _scaffoldKey,
        appBar: AppTopBar(
          title: 'SkidKZ',
          onMenu: _openDrawer,
          actions: const [],
        ),
        drawer: drawer,
        bottomNavigationBar: bottomNav,
        body: widget.child,
      ),
    );
  }
}
