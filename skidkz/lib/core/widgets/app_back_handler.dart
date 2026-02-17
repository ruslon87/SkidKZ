// lib/core/widgets/app_back_handler.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackHandler extends StatefulWidget {
  const AppBackHandler({
    super.key,
    required this.router,
    required this.messengerKey,
    required this.child,
  });

  final GoRouter router;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPress;
  bool _busy = false;

  Future<dynamic> Function(MethodCall call)? _prevHandler;

  NavigatorState? get _nav =>
      widget.router.routerDelegate.navigatorKey.currentState;

  String get _path =>
      widget.router.routeInformationProvider.value.uri.path;

  bool _isBuyerTab(String path) =>
      path.startsWith('/buyer/home') ||
      path.startsWith('/buyer/catalog') ||
      path.startsWith('/buyer/favorites') ||
      path.startsWith('/buyer/cart') ||
      path.startsWith('/buyer/profile');

  bool _isBuyerHome(String path) => path.startsWith('/buyer/home');

  void _showExitHint() {
    widget.messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<bool> _handleBack() async {
    if (_busy) return true;
    _busy = true;
    try {
      // 1) закрыть диалоги/боттомшиты
      final nav = _nav;
      if (nav != null && nav.canPop()) {
        nav.pop();
        return true;
      }

      final path = _path;

      // 2) на любой buyer-вкладке кроме home -> на home
      if (_isBuyerTab(path) && !_isBuyerHome(path)) {
        widget.router.go('/buyer/home');
        return true;
      }

      // 3) на home -> двойной back выход
      if (_isBuyerHome(path)) {
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          _showExitHint();
          return true;
        }
        SystemNavigator.pop();
        return true;
      }

      // 4) всё остальное -> на buyer/home
      widget.router.go('/buyer/home');
      return true;
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      _busy = false;
    }
  }

  @override
  void initState() {
    super.initState();

    // 100% перехват hardware back
    _prevHandler = SystemChannels.navigation.setMethodCallHandler((call) async {
      if (call.method == 'popRoute' || call.method == 'maybePop') {
        return await _handleBack(); // true = consumed
      }
      return _prevHandler?.call(call);
    });
  }

  @override
  void dispose() {
    SystemChannels.navigation.setMethodCallHandler(_prevHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
