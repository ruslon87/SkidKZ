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

  Future<void> _handleBack() async {
    final router = GoRouter.of(context);
    final path = router.routeInformationProvider.value.uri.path;

    // 1) Закрыть drawer
    if (_drawerOpen()) {
      _closeDrawer();
      return;
    }

    // 2) Если есть что pop
    if (router.canPop()) {
      router.pop();
      return;
    }

    // 3) Если НЕ главный экран buyer
    if (path != widget.mainPath) {
      router.go(widget.mainPath);
      return;
    }

    // 4) Двойной back для выхода
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
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        await _handleBack();
        return true; // мы обработали back, систему не пускаем дальше
      },
      child: widget.child,
    );
  }
}
