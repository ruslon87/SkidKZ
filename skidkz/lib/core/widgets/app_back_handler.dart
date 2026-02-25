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

  // Главные экраны по ролям (на них двойной back = выход)
  static const Set<String> _mainRoutes = <String>{
    '/buyer/home',
    '/seller/products',
    '/wanghong/home',
    '/admin/moderation',
  };

  bool _isMainScreen(String path) {
    if (path == '/' || path == '/buyer' || path == '/cabinet') return true;
    return _mainRoutes.contains(path);
  }

  String _roleMainForPath(String path) {
    if (path.startsWith('/seller')) return '/seller/products';
    if (path.startsWith('/wanghong')) return '/wanghong/home';
    if (path.startsWith('/admin')) return '/admin/moderation';
    return '/buyer/home';
  }

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
      final router = widget.router;
      final path = router.routeInformationProvider.value.uri.path;

      // 0) ВАЖНО: /login пусть обрабатывает свой PopScope (шаги ввода номера/кода).
      // Если мы тут "съедим" back — логика внутри LoginScreen сломается.
      if (path.startsWith('/login')) {
        return; // не обрабатываем, ниже вернём false (событие уйдёт внутрь)
      }

      // 1) Сначала закрываем то, что реально может "попнуться" в Navigator:
      // drawer, dialogs, bottom sheets, push-страницы внутри вложенных Navigator'ов.
      final nav = router.routerDelegate.navigatorKey.currentState;
      if (nav != null && nav.canPop()) {
        nav.pop();
        return;
      }

      // 2) Если go_router знает, что может pop — pop через router
      // (иногда это полезно для страниц, открытых push’ем через go_router).
      if (router.canPop()) {
        router.pop();
        return;
      }

      // 3) На главном экране — двойной back для выхода
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

      // 4) На любом другом экране — возвращаемся на главный экран текущей роли
      router.go(_roleMainForPath(path));
    } finally {
      // анти-дребезг, чтобы не ловить двойные события
      await Future<void>.delayed(const Duration(milliseconds: 60));
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        final path = widget.router.routeInformationProvider.value.uri.path;

        // /login отдаём внутрь LoginScreen (его PopScope)
        if (path.startsWith('/login')) {
          return false; // НЕ обработали -> пусть обработает экран логина
        }

        await _handleBack();
        return true; // обработали -> ОС не должна закрывать приложение
      },
      child: widget.child,
    );
  }
}
