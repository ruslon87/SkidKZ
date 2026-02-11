// lib/core/widgets/app_back_handler.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackHandler extends StatefulWidget {
  const AppBackHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPress;

  bool _isBuyerHome(String location) {
    return location == '/' ||
        location == '/buyer' ||
        location.startsWith('/buyer/home');
  }

  bool _isBuyerArea(String location) {
    return location == '/' || location.startsWith('/buyer');
  }

  Future<void> _handleBack() async {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.fullPath ??
        router.routeInformationProvider.value.uri.toString();

    // 1) Если есть возможность pop — всегда pop (это “нормальный назад”)
    if (router.canPop()) {
      router.pop();
      return;
    }

    // 2) Логин без стека: назад НЕ должен закрывать приложение
    if (location.startsWith('/login')) {
      router.go('/buyer/home');
      return;
    }

    // 3) В buyer-зоне, но не на "Магазин" — назад ведёт на "Магазин"
    if (_isBuyerArea(location) && !_isBuyerHome(location)) {
      router.go('/buyer/home');
      return;
    }

    // 4) На "Магазин" — двойной back для выхода
    if (_isBuyerHome(location)) {
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
        return;
      }

      SystemNavigator.pop();
      return;
    }

    // 5) Для остальных “краёв” (если вдруг)
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.child,
    );
  }
}
