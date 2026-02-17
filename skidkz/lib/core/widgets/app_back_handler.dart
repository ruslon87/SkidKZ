// lib/core/widgets/app_back_handler.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackHandler extends StatefulWidget {
  final GoRouter router;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  const AppBackHandler({
    super.key,
    required this.router,
    required this.messengerKey,
    required this.child,
  });

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPress;
  Future<dynamic> Function(MethodCall call)? _prevHandler;
  bool _busy = false;

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
      // 1) Сначала закрываем то, что реально "попается" (диалоги/боттомшиты/пуш-роуты)
      final nav = _nav;
      if (nav != null && nav.canPop()) {
        nav.pop();
        return true; // consumed
      }

      final path = _path;

      // 2) Если мы на вкладках buyer, но не home — возвращаемся на home
      if (_isBuyerTab(path) && !_isBuyerHome(path)) {
        widget.router.go('/buyer/home');
        return true;
      }

      // 3) Если мы на buyer/home — двойной back = выход
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

      // 4) Всё остальное — тоже на buyer/home
      widget.router.go('/buyer/home');
      return true;
    } finally {
      // маленькая защита от двойного срабатывания
      await Future<void>.delayed(const Duration(milliseconds: 80));
      _busy = false;
    }
  }

  @override
  void initState() {
    super.initState();

    // 100% перехват hardware back через системный канал навигации
    _prevHandler = SystemChannels.navigation.setMethodCallHandler((call) async {
      if (call.method == 'popRoute' || call.method == 'maybePop') {
        final consumed = await _handleBack();
        // true = мы обработали, ОС не должна закрывать/сворачивать
        return consumed;
      }
      // остальное — отдаем как есть
      return _prevHandler?.call(call);
    });
  }

  @override
  void dispose() {
    // вернем обработчик назад (или сбросим)
    SystemChannels.navigation.setMethodCallHandler(_prevHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Никаких GoRouter.of(context) и context.go() здесь нет вообще
    return widget.child;
  }
}
