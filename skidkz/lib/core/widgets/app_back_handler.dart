// lib/core/widgets/app_back_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackHandler extends StatefulWidget {
  final Widget child;
  final GoRouter router;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  const AppBackHandler({
    super.key,
    required this.child,
    required this.router,
    required this.messengerKey,
  });

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPress;

  int _tabIndexByPath(String path) {
    if (path.startsWith('/buyer/catalog')) return 1;
    if (path.startsWith('/buyer/favorites')) return 2;
    if (path.startsWith('/buyer/cart')) return 3;
    if (path.startsWith('/buyer/profile')) return 4;
    return 0; // /buyer/home по умолчанию
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        final path =
            widget.router.routerDelegate.currentConfiguration.uri.path;

        // всё, что не buyer — возвращаем на buyer/home (на всякий)
        if (!path.startsWith('/buyer')) {
          widget.router.go('/buyer/home');
          return true;
        }

        final idx = _tabIndexByPath(path);

        // если не главная вкладка — возвращаемся на главную
        if (idx != 0) {
          widget.router.go('/buyer/home');
          return true;
        }

        // главная вкладка: double back exit
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;

          widget.messengerKey.currentState
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
      },
      child: widget.child,
    );
  }
}
