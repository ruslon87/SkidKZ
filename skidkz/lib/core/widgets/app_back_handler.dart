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
  static const Duration _doubleBackTimeout = Duration(seconds: 2);

  static const String _buyerMain = '/buyer/home';
  static const String _sellerMain = '/seller/products';
  static const String _adminMain = '/admin/moderation';
  static const String _wanghongMain = '/wanghong/home';
  static const String _roleSelect = '/role-select';

  DateTime? _lastBackPress;
  bool _busy = false;

  NavigatorState? get _nav =>
      widget.router.routerDelegate.navigatorKey.currentState;

  String get _path {
    final uri = widget.router.routeInformationProvider.value.uri;
    return uri.path.isEmpty ? '/' : uri.path;
  }

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

  String? _mainRouteForPath(String path) {
    if (path == '/' || path.startsWith('/buyer')) return _buyerMain;
    if (path.startsWith('/seller')) return _sellerMain;
    if (path.startsWith('/admin')) return _adminMain;
    if (path.startsWith('/wanghong')) return _wanghongMain;
    return null;
  }

  bool _isMainOfRole(String path, String mainRoute) {
    if (mainRoute == _buyerMain) {
      return path == '/' || path == '/buyer' || path == _buyerMain;
    }
    return path == mainRoute;
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
      final mainRoute = _mainRouteForPath(path);

      if (mainRoute != null && !_isMainOfRole(path, mainRoute)) {
        _lastBackPress = null;
        widget.router.go(mainRoute);
        return;
      }

      // Для seller/admin/wanghong: back на корневой вкладке ведет к выбору роли.
      if (mainRoute != null && mainRoute != _buyerMain) {
        widget.router.go(_roleSelect);
        return;
      }

      // Для buyer/home и role-select: двойной back для выхода.
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
