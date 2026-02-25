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

  /// Главные экраны по ролям (двойной back = выход)
  static const Set<String> _mainRoutes = <String>{
    '/buyer/home',
    '/seller/products',
    '/wanghong/home',
    '/admin/moderation',
  };

  bool _isMainScreen(String path) {
    if (path == '/' || path == '/buyer' || path == '/cabinet') return true;
    return _mainRoutes.contains(path);
  }

  String _roleMainForPath(String path) {
    if (path.startsWith('/seller')) return '/seller/products';
    if (path.startsWith('/wanghong')) return '/wanghong/home';
    if (path.startsWith('/admin')) return '/admin/moderation';
    return '/buyer/home';
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

      // 1) Если можно закрыть drawer/диалог/экран — закрываем
      if (nav != null && nav.canPop()) {
        nav.pop();
        return;
      }

      // 2) Главный экран — двойной back для выхода
      if (_isMainScreen(path)) {
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

      // 3) Любой другой экран — на главный экран текущей роли
      widget.router.go(_roleMainForPath(path));
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        await _handleBack();
        return true; // ОС не должна сворачивать приложение
      },
      child: widget.child,
    );
  }
}
