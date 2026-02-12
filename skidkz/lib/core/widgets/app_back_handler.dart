// skidkz/lib/core/widgets/app_back_handler.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackHandler extends StatefulWidget {
  const AppBackHandler({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPress;

  String get _location =>
      widget.router.routeInformationProvider.value.uri.toString();

  NavigatorState? get _nav =>
      widget.router.routerDelegate.navigatorKey.currentState;

  bool _isBuyerHome(String loc) =>
      loc == '/' || loc == '/buyer' || loc.startsWith('/buyer/home');

  bool _isBuyerArea(String loc) => loc == '/' || loc.startsWith('/buyer');

  Future<bool> _handleBack() async {
    final loc = _location;
    final nav = _nav;

    if (nav == null) {
      SystemNavigator.pop();
      return true;
    }

    // 1) Закрыть верхний route (диалог/страница и т.д.)
    if (nav.canPop()) {
      nav.pop();
      return true;
    }

    // 2) Логин без стека -> назад на магазин
    if (loc.startsWith('/login')) {
      widget.router.go('/buyer/home');
      return true;
    }

    // 3) Любая вкладка buyer кроме home -> назад на магазин
    if (_isBuyerArea(loc) && !_isBuyerHome(loc)) {
      widget.router.go('/buyer/home');
      return true;
    }

    // 4) На магазине -> двойной выход
    if (_isBuyerHome(loc)) {
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

    // 5) Фолбэк
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_handleBack());
      },
      child: widget.child,
    );
  }
}
