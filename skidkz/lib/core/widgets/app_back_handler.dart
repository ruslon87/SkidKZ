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

class _AppBackHandlerState extends State<AppBackHandler>
    with WidgetsBindingObserver {
  static const String _mainRoute = '/buyer/home';
  static const Duration _doubleBackTimeout = Duration(seconds: 2);

  DateTime? _lastBackPress;
  bool _busy = false;

  NavigatorState? get _nav =>
      widget.router.routerDelegate.navigatorKey.currentState;

  String get _path {
    final uri = widget.router.routeInformationProvider.value.uri;
    return uri.path.isEmpty ? '/' : uri.path;
  }

  bool _isMainScreen(String path) =>
      path == '/' || path == '/buyer' || path == _mainRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    await _handleBack();
    return true;
  }

  void _showExitHint() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз, чтобы выйти'),
          duration: _doubleBackTimeout,
        ),
      );
  }

  Future<void> _handleBack() async {
    if (_busy) return;
    _busy = true;

    try {
      final nav = _nav;
      if (nav != null) {
        final popped = await nav.maybePop();
        if (popped) return;
      }

      final path = _path;
      if (!_isMainScreen(path)) {
        _lastBackPress = null;
        widget.router.go(_mainRoute);
        return;
      }

      final now = DateTime.now();
      if (_lastBackPress == null ||
          now.difference(_lastBackPress!) > _doubleBackTimeout) {
        _lastBackPress = now;
        _showExitHint();
        return;
      }

      await SystemNavigator.pop();
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 100));
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
