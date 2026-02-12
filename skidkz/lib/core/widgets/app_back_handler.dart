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

  Uri get _uri => widget.router.routeInformationProvider.value.uri;

  NavigatorState? get _nav =>
      widget.router.routerDelegate.navigatorKey.currentState;

  bool _isBuyerHome(String path) =>
      path == '/' || path == '/buyer' || path.startsWith('/buyer/home');

  bool _isExitHome(String path) =>
      _isBuyerHome(path) ||
      path.startsWith('/seller/products') ||
      path.startsWith('/wanghong/home') ||
      path.startsWith('/admin/moderation');

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
    final nav = _nav;
    final path = _uri.path;

    // Router ещё не привязан: ничего не делаем, чтобы не закрыть приложение случайно.
    if (nav == null) return;

    // 1) Сначала закрываем верхний маршрут: drawer/dialog/bottom-sheet/вложенный экран.
    if (nav.canPop()) {
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

    // 3) На внутренних экранах раздела — назад на "главную" раздела.
    final sectionHome = _homeForPath(path);
    if (sectionHome != null && path != sectionHome) {
      widget.router.go(sectionHome);
      return;
    }

    // 4) На главных разделов — двойное нажатие для выхода.
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

    // 5) Фолбэк: вернуться на витрину, а не сворачивать приложение.
    widget.router.go('/buyer/home');
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
