// lib/core/widgets/app_back_handler.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Единый back-хендлер для shell'ов.
///
/// Логика:
/// 1) Если открыт Drawer (передан [scaffoldKey]) — закрыть Drawer.
/// 2) Если роутер может pop() — pop().
/// 3) Если текущий путь != [mainPath] — перейти на [mainPath].
/// 4) Если уже на [mainPath] — двойное нажатие для выхода.
///
/// Важно:
/// - Этот виджет должен быть *потомком Router*, т.е. ставить его в ShellRoute builder
///   или внутри экранов Shell'а. Если повесить в MaterialApp.router.builder — back
///   не перехватывается (и/или даст ошибку контекста Router).
class AppBackHandler extends StatefulWidget {
  const AppBackHandler({
    super.key,
    required this.child,
    required this.mainPath,
    this.scaffoldKey,
  });

  final Widget child;
  final String mainPath;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBack;
  bool _busy = false;

  bool _drawerOpen() {
    return widget.scaffoldKey?.currentState?.isDrawerOpen ?? false;
  }

  void _closeDrawer() {
    widget.scaffoldKey?.currentState?.closeDrawer();
  }

  void _showExitHint() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _handleBack() async {
    if (_busy) return;
    _busy = true;

    try {
      final router = GoRouter.maybeOf(context);
      if (router == null) {
        // Значит, виджет повешен не под Router — ничего не делаем.
        return;
      }

      final path = router.routeInformationProvider.value.uri.path;

      // 1) Drawer
      if (_drawerOpen()) {
        _closeDrawer();
        return;
      }

      // 2) Pop
      if (router.canPop()) {
        router.pop();
        return;
      }

      // 3) Не главный экран — на главный
      if (path != widget.mainPath) {
        router.go(widget.mainPath);
        return;
      }

      // 4) Главный экран — двойной back для выхода
      final now = DateTime.now();
      if (_lastBack == null ||
          now.difference(_lastBack!) > const Duration(seconds: 2)) {
        _lastBack = now;
        _showExitHint();
        return;
      }

      SystemNavigator.pop();
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.child,
    );
  }
}
