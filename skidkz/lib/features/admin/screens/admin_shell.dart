// lib/features/admin/screens/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/widgets/app_scaffold.dart';
import 'package:skidkz/core/widgets/app_top_bar.dart';
import 'package:skidkz/core/widgets/app_drawer.dart';
import 'package:skidkz/core/widgets/app_bottom_nav.dart';

class AdminShellScope extends InheritedWidget {
  final VoidCallback openDrawer;

  const AdminShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static AdminShellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminShellScope>()!;

  @override
  bool updateShouldNotify(AdminShellScope oldWidget) => false;
}

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  int _calcIndexFromLocation(String location) {
    if (location.startsWith('/admin/moderation')) return 0;
    if (location.startsWith('/admin/users')) return 1;
    if (location.startsWith('/admin/finance')) return 2;
    return 0;
  }

  void _goByIndex(int i) {
    switch (i) {
      case 0:
        context.go('/admin/moderation');
        break;
      case 1:
        context.go('/admin/users');
        break;
      case 2:
        context.go('/admin/finance');
        break;
      default:
        context.go('/admin/moderation');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _calcIndexFromLocation(location);

    final drawer = AppDrawer(
      headerTitle: 'SkidKZ',
      headerSubtitle: 'Админ',
      items: [
        AppDrawerItem(
          icon: Icons.gavel_outlined,
          title: 'Модерация',
          onTap: () => context.go('/admin/moderation'),
        ),
        AppDrawerItem(
          icon: Icons.people_outline,
          title: 'Пользователи',
          onTap: () => context.go('/admin/users'),
        ),
        AppDrawerItem(
          icon: Icons.payments_outlined,
          title: 'Финансы',
          onTap: () => context.go('/admin/finance'),
        ),
      ],
      bottomItems: [
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
        AppNavItem(icon: Icons.gavel_rounded, label: 'Модерация'),
        AppNavItem(icon: Icons.people_rounded, label: 'Пользователи'),
        AppNavItem(icon: Icons.payments_rounded, label: 'Финансы'),
      ],
    );

    return AdminShellScope(
      openDrawer: _openDrawer,
      child: AppScaffold(
        scaffoldKey: _scaffoldKey,
        appBar: AppTopBar(
          title: 'Админ-панель',
          onMenu: _openDrawer,
        ),
        drawer: drawer,
        bottomNavigationBar: bottomNav,
        body: widget.child,
      ),
    );
  }
}
