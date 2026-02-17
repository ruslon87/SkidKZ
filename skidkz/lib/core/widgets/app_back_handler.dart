// lib/core/widgets/app_back_handler.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class AppBackHandler extends StatefulWidget {
  final Widget child;
  final GoRouter router;

  const AppBackHandler({
    super.key,
    required this.child,
    required this.router,
  });

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        final location = widget.router.routerDelegate.currentConfiguration.uri.path;

        // Если не buyer – просто блокируем
        if (!location.startsWith('/buyer')) {
          widget.router.go('/buyer/home');
          return true;
        }

        // Определяем текущую вкладку
        int currentIndex = 0;
        if (location.startsWith('/buyer/catalog')) currentIndex = 1;
        if (location.startsWith('/buyer/favorites')) currentIndex = 2;
        if (location.startsWith('/buyer/cart')) currentIndex = 3;
        if (location.startsWith('/buyer/profile')) currentIndex = 4;

        // Если не главная вкладка → перейти на главную
        if (currentIndex != 0) {
          widget.router.go('/buyer/home');
          return true;
        }

        // Если главная вкладка → двойной выход
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
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
      },
      child: widget.child,
    );
  }
}
