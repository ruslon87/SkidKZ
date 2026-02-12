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

  NavigatorState? get _nav =>
      widget.router.routerDelegate.navigatorKey.currentState;

  bool _isBuyerHome(String path) =>
      path == '/' || path == '/buyer' || path == '/buyer/home';

  bool _isExitHome(String path) =>
      _isBuyerHome(path) ||
      path == '/seller/products' ||
      path == '/wanghong/home' ||
      path == '/admin/moderation';

  String? _homeForPath(String path) {
    if (path == '/' || path.startsWith('/buyer')) return '/buyer/home';
    if (path.startsWith('/seller')) return '/seller/products';
    if (path.startsWith('/wanghong')) return '/wanghong/home';
    if (path.startsWith('/admin')) return '/admin/moderation';
    return null;
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
      final nav = _nav;
      final path = _uri.path;

      // 1) Если есть что pop (drawer/dialog/bottomsheet/вложенный экран) — попаем.
      if (nav != null && nav.canPop()) {
        nav.pop();
        return;
      }

      // 2) Экраны входа/инфо/онбординга — возвращаем на витрину.
      if (path.startsWith('/login') ||
          path.startsWith('/role-select') ||
          path.startsWith('/onboarding') ||
          path.startsWith('/info')) {
        widget.router.go('/buyer/home');
        return;
      }

      // 3) Внутри раздела — назад на “главную” раздела.
      final sectionHome = _homeForPath(path);
      if (sectionHome != null && path != sectionHome) {
        widget.router.go(sectionHome);
        return;
      }

      // 4) На главных — двойное нажатие для выхода.
      if (_isExitHome(path)) {
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

      // 5) Фолбэк: на витрину.
      widget.router.go('/buyer/home');
    } finally {
      // небольшая задержка, чтобы не словить двойной вызов от разных механизмов back
      await Future<void>.delayed(const Duration(milliseconds: 60));
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // BackButtonListener перехватывает системный Back на уровне Router,
    // то, чего PopScope не делает когда pop'ать нечего.
    return BackButtonListener(
      onBackButtonPressed: () async {
        unawaited(_handleBack());
        return true; // ВАЖНО: говорим системе "мы обработали back"
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
