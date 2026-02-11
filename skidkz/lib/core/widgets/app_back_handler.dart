// lib/core/widgets/app_back_handler.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackHandler extends StatefulWidget {
  const AppBackHandler({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPress;

  bool _isBuyerHome(String loc) =>
      loc == '/' || loc == '/buyer' || loc.startsWith('/buyer/home');

  bool _isBuyerArea(String loc) => loc == '/' || loc.startsWith('/buyer');

  Future<bool> _onBackPressed() async {
    final router = GoRouter.of(context);

    // Текущий маршрут максимально надёжно берём из routeInformationProvider
    final loc = router.routeInformationProvider.value.uri.toString();

    // 0) Если открыто что-то поверх (dialog/bottomsheet/menu) — закрыть это
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) {
      rootNav.pop();
      return true; // обработали
    }

    // 1) Если есть история роутера — pop (обычный "назад")
    if (router.canPop()) {
      router.pop();
      return true;
    }

    // 2) На логине без стека — назад НЕ закрывает приложение
    if (loc.startsWith('/login')) {
      router.go('/buyer/home');
      return true;
    }

    // 3) В buyer-зоне, но не на "Магазин" — назад ведёт на "Магазин"
    // (это закрывает твой кейс: профиль/каталог/и т.п. => на главную)
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

    // 5) Фолбэк: если вдруг где-то вне buyer-зоны
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // BackButtonListener — именно то, что ловит системную кнопку Back глобально.
    return BackButtonListener(
      onBackButtonPressed: _onBackPressed,
      child: widget.child,
    );
  }
}
