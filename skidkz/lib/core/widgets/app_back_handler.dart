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
    Navigator.of(context).pop();
  }

  Future<bool> _onBack() async {
    final router = GoRouter.of(context);
    final path = router.routeInformationProvider.value.uri.path;

    // 1️⃣ Закрыть drawer
    if (_drawerOpen()) {
      _closeDrawer();
      return true;
    }

    // 2️⃣ Если есть что pop — pop
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true;
    }

    // 3️⃣ Если НЕ главный экран buyer — вернуться домой
    if (path != widget.mainPath) {
      router.go(widget.mainPath);
      return true;
    }

    // 4️⃣ Главный экран → двойной back
    final now = DateTime.now();
    if (_lastBack == null ||
        now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;

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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child: widget.child,
    );
  }
}
