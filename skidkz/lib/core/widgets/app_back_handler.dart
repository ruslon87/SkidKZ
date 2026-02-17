// lib/core/widgets/app_back_handler.dart
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

  bool _isBuyerMain(String path) => path == '/buyer/home';

  bool _isBuyerTab(String path) =>
      path.startsWith('/buyer/home') ||
      path.startsWith('/buyer/catalog') ||
      path.startsWith('/buyer/favorites') ||
      path.startsWith('/buyer/cart') ||
      path.startsWith('/buyer/profile');

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

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        // 1) сначала пытаемся закрыть всё, что реально "попается" (диалоги/листы)
        final nav = widget.router.routerDelegate.navigatorKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return true; // ВАЖНО: событие consumed
        }

        // 2) читаем текущий путь напрямую из router (без context)
        final path = widget.router.routeInformationProvider.value.uri.path;

        // 3) если мы на любой вкладке buyer, но НЕ на главной — уходим на главную
        if (_isBuyerTab(path) && !_isBuyerMain(path)) {
          widget.router.go('/buyer/home');
          return true;
        }

        // 4) если мы на главной buyer — double back exit
        if (_isBuyerMain(path)) {
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

        // 5) всё прочее — отправляем на главную buyer
        widget.router.go('/buyer/home');
        return true;
      },
      child: widget.child,
    );
  }
}
