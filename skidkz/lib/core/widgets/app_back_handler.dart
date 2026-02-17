// lib/core/widgets/app_back_handler.dart
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

  static const String _mainRoute = '/buyer/home';

  bool _isMainScreen(String path) =>
      path == '/' || path == '/buyer' || path == _mainRoute;

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

      // 1) pop (dialog/bottomsheet/etc)
      if (nav != null && nav.canPop()) {
        nav.pop();
        return;
      }

      // 2) На главном экране — двойной back для выхода
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

      // 3) На любом другом экране сначала возвращаем на главный.
      widget.router.go(_mainRoute);
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_handleBack());
      },
      child: widget.child,
    );
  }
}
