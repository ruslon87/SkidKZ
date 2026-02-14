// lib/features/wanghong/screens/wanghong_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_drawer.dart';
import 'package:skidkz/core/widgets/app_bottom_nav.dart';

class WanghongShellScope extends InheritedWidget {
  final VoidCallback openDrawer;

  const WanghongShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static WanghongShellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WanghongShellScope>()!;

  @override
  bool updateShouldNotify(WanghongShellScope oldWidget) => false;
}

class WanghongShell extends StatefulWidget {
  final Widget child;

  const WanghongShell({super.key, required this.child});

  @override
  State<WanghongShell> createState() => _WanghongShellState();
}

class _WanghongShellState extends State<WanghongShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  int _calcIndexFromLocation(String location) {
    if (location.startsWith('/wanghong/home')) return 0;
    if (location.startsWith('/wanghong/deals')) return 1;
    if (location.startsWith('/wanghong/wallet')) return 2;
    return 0;
  }

  void _goByIndex(int i) {
    switch (i) {
      case 0:
        context.go('/wanghong/home');
        break;
      case 1:
        context.go('/wanghong/deals');
        break;
      case 2:
        context.go('/wanghong/wallet');
        break;
      default:
        context.go('/wanghong/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _calcIndexFromLocation(location);

    final drawer = AppDrawer(
      headerTitle: 'SkidKZ',
      headerSubtitle: 'Ванхун',
      items: [
        AppDrawerItem(
          icon: Icons.dashboard_outlined,
          title: 'Главная',
          onTap: () => context.go('/wanghong/home'),
        ),
        AppDrawerItem(
          icon: Icons.local_offer_outlined,
          title: 'Сделки',
          onTap: () => context.go('/wanghong/deals'),
        ),
        AppDrawerItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Кошелёк',
          onTap: () => context.go('/wanghong/wallet'),
        ),
      ],
      bottomItems: [
        AppDrawerItem(
          icon: Icons.info_outline,
          title: 'Инфо для ванхуна',
          onTap: () => context.go('/info/wanghong'),
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
        AppNavItem(icon: Icons.dashboard_rounded, label: 'Главная'),
        AppNavItem(icon: Icons.local_offer_rounded, label: 'Сделки'),
        AppNavItem(icon: Icons.account_balance_wallet_rounded, label: 'Кошелёк'),
      ],
    );

    return WanghongShellScope(
      openDrawer: _openDrawer,
      child: AppScaffold(
        scaffoldKey: _scaffoldKey,
        appBar: AppTopBar(
          title: 'Кабинет ванхуна',
          onMenu: _openDrawer,
        ),
        drawer: drawer,
        bottomNavigationBar: bottomNav,
        body: widget.child,
      ),
    );
  }
}
