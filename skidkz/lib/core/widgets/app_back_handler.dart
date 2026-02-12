// lib/core/widgets/app_back_handler.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
  DateTime? _lastBackPressed;

  bool _isMainRoute(String location) {
    return location == '/buyer/home' ||
        location == '/seller/products' ||
        location == '/wanghong/home' ||
        location == '/admin/moderation';
  }

  Future<bool> _handleBack() async {
    final nav = widget.router.routerDelegate.navigatorKey.currentState;
    final location = widget.router.routeInformationProvider.value.location;

    if (nav == null) return false;

    // 1. Если есть что pop — попаем
    if (nav.canPop()) {
      nav.pop();
      return false;
    }

    // 2. Если не на главной — возвращаем на главную раздела
    if (!_isMainRoute(location)) {
      if (location.startsWith('/buyer')) {
        widget.router.go('/buyer/home');
      } else if (location.startsWith('/seller')) {
        widget.router.go('/seller/products');
      } else if (location.startsWith('/wanghong')) {
        widget.router.go('/wanghong/home');
      } else if (location.startsWith('/admin')) {
        widget.router.go('/admin/moderation');
      } else {
        widget.router.go('/buyer/home');
      }
      return false;
    }

    // 3. На главной — двойное нажатие
    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз для выхода'),
          duration: Duration(seconds: 2),
        ),
      );

      return false;
    }

    // Второе нажатие — выходим
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: widget.child,
    );
  }
}
