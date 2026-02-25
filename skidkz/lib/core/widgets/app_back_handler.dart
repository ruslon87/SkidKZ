import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppBackHandler extends StatefulWidget {
  const AppBackHandler({
    super.key,
    required this.child,
    required this.mainPath,
    this.scaffoldKey,
  });

  final Widget child;
  final String mainPath;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBack;

  bool _drawerOpen() {
    return widget.scaffoldKey?.currentState?.isDrawerOpen ?? false;
  }

  void _closeDrawer() {
    widget.scaffoldKey?.currentState?.closeDrawer();
  }

  Future<bool> _onBack() async {
    final router = GoRouter.of(context);
    final path = router.routeInformationProvider.value.uri.path;

    // 1) Закрыть drawer
    if (_drawerOpen()) {
      _closeDrawer();
      return false; // мы обработали, систему не пускаем дальше
    }

    // 2) Если есть что pop — pop через go_router
    if (router.canPop()) {
      router.pop();
      return false;
    }

    // 3) Если НЕ главный экран buyer — вернуться домой
    if (path != widget.mainPath) {
      router.go(widget.mainPath);
      return false;
    }

    // 4) Главный экран → двойной back
    final now = DateTime.now();
    if (_lastBack == null ||
        now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Нажмите ещё раз, чтобы выйти'),
            duration: Duration(seconds: 2),
          ),
        );

      return false;
    }

    SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _onBack();
      },
      child: widget.child,
    );
  }
}
