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
  bool _busy = false;

  NavigatorState? get _nav =>
      widget.router.routerDelegate.navigatorKey.currentState;

  Uri get _uri => widget.router.routeInformationProvider.value.uri;

  bool _isBuyerHome(String path) =>
      path == '/' || path == '/buyer' || path == '/buyer/home';

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
      final nav = _nav;
      final path = _uri.path;

      // 1) pop (drawer/dialog/etc)
      if (nav != null && nav.canPop()) {
        nav.pop();
        return;
      }

      // 2) ДВОЙНОЙ ВЫХОД только на buyer/home
      if (_isBuyerHome(path)) {
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          _showExitHint();
          return;
        }
        SystemNavigator.pop();
        return;
      }

      // 3) Внутри buyer — назад на home
      if (path.startsWith('/buyer')) {
        widget.router.go('/buyer/home');
        return;
      }

      // 4) В других ролях — на role-select (как у тебя в админке задумано)
      if (path.startsWith('/seller') ||
          path.startsWith('/admin') ||
          path.startsWith('/wanghong')) {
        widget.router.go('/role-select');
        return;
      }

      // 5) Фолбэк
      widget.router.go('/buyer/home');
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        unawaited(_handleBack());
        return true; // мы обработали back
      },
      child: widget.child,
    );
  }
}
