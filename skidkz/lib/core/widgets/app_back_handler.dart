// lib/core/widgets/app_back_handler.dart

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

  bool _isBuyerHome(String loc) =>
      loc == '/' || loc == '/buyer' || loc.startsWith('/buyer/home');

  bool _isBuyerArea(String loc) => loc == '/' || loc.startsWith('/buyer');

  /// Текущий "location" берём из RouteInformationProvider — он есть всегда.
  String _location() => widget.router.routeInformationProvider.value.uri.toString();

  NavigatorState? _rootNav() => widget.router.routerDelegate.navigatorKey.currentState;

  Future<bool> _onBackPressed() async {
    final router = widget.router;
    final loc = _location();

    // 0) Если есть что закрыть в root Navigator (dialog/bottomsheet и т.п.) — закрыть
    final rootNav = _rootNav();
    if (rootNav != null && rootNav.canPop()) {
      rootNav.pop();
      return true;
    }

    // 1) Если go_router может pop — pop
    if (router.canPop()) {
      router.pop();
      return true;
    }

    // 2) Логин без стека — назад НЕ закрывает приложение
    if (loc.startsWith('/login')) {
      router.go('/buyer/home');
      return true;
    }

    // 3) В buyer-зоне, но не на "Магазин" — назад ведёт на "Магазин"
    if (_isBuyerArea(loc) && !_isBuyerHome(loc)) {
      router.go('/buyer/home');
      return true;
    }

    // 4) На "Магазин" — двойной back = выход
    if (_isBuyerHome(loc)) {
      final now = DateTime.now();
      final last = _lastBackPress;

      if (last == null || now.difference(last) > const Duration(seconds: 2)) {
        _lastBackPress = now;

        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger
          ?..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Нажмите ещё раз, чтобы выйти'),
              duration: Duration(seconds: 2),
            ),
          );

        return true;
      }

      SystemNavigator.pop();
      return true;
    }

    // 5) Фолбэк — закрыть
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // BackButtonListener ловит системный Back глобально
    return BackButtonListener(
      onBackButtonPressed: _onBackPressed,
      child: widget.child,
    );
  }
}
