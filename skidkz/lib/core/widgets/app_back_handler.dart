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

  Uri get _uri => widget.router.routeInformationProvider.value.uri;
  NavigatorState? get _nav => widget.router.routerDelegate.navigatorKey.currentState;

  bool _isBuyerHome(String path) => path == '/' || path == '/buyer' || path == '/buyer/home';

  String _pathOnly() => _uri.path;

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
      final path = _pathOnly();

      // 1) Если есть что pop (drawer/dialog/bottomsheet/вложенный экран) — попаем
      if (nav != null && nav.canPop()) {
        nav.pop();
        return;
      }

      // 2) Логин/инфо/онбординг — назад на витрину
      if (path.startsWith('/login') ||
          path.startsWith('/role-select') ||
          path.startsWith('/onboarding') ||
          path.startsWith('/info')) {
        widget.router.go('/buyer/home');
        return;
      }

      // 3) Внутри buyer — на /buyer/home
      if (path.startsWith('/buyer') && !_isBuyerHome(path)) {
        widget.router.go('/buyer/home');
        return;
      }

      // 4) Внутри seller — на /seller/products, а если уже там — на role-select
      if (path.startsWith('/seller')) {
        if (path != '/seller/products') {
          widget.router.go('/seller/products');
        } else {
          widget.router.go('/role-select');
        }
        return;
      }

      // 5) Внутри wanghong — на /wanghong/home, а если уже там — на role-select
      if (path.startsWith('/wanghong')) {
        if (path != '/wanghong/home') {
          widget.router.go('/wanghong/home');
        } else {
          widget.router.go('/role-select');
        }
        return;
      }

      // 6) Внутри admin — на /admin/moderation, а если уже там — на role-select
      if (path.startsWith('/admin')) {
        if (path != '/admin/moderation') {
          widget.router.go('/admin/moderation');
        } else {
          widget.router.go('/role-select');
        }
        return;
      }

      // 7) ДВОЙНОЙ ВЫХОД — ТОЛЬКО НА BUYER HOME
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

      // 8) Фолбэк
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
        return true; // важно: система не должна сворачивать сама
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          unawaited(_handleBack());
        },
        child: widget.child,
      ),
    );
  }
}
