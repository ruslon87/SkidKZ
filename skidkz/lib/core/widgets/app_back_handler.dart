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
  DateTime? _lastBackPress;

  bool _isDrawerOpen() {
    final st = widget.scaffoldKey?.currentState;
    return st?.isDrawerOpen ?? false;
  }

  void _closeDrawer() {
    widget.scaffoldKey?.currentState?.closeDrawer();
  }

  String _currentPath() {
    final r = GoRouter.maybeOf(context);
    if (r == null) return widget.mainPath;
    return r.routeInformationProvider.value.uri.path;
  }

  void _showExitSnack() {
    final m = ScaffoldMessenger.maybeOf(context);
    m
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  /// ВАЖНО:
  /// BackButtonListener ждёт bool:
  /// - true  => мы обработали back, ОС дальше НЕ пускаем (не закрывает Activity)
  /// - false => ОС продолжит стандартное поведение (закроет Activity)
  Future<bool> _onBackPressed() async {
    final r = GoRouter.maybeOf(context);

    // 1) Drawer открыт -> закрыть drawer
    if (_isDrawerOpen()) {
      _closeDrawer();
      return true;
    }

    // 2) Если go_router может pop -> pop
    if (r != null && r.canPop()) {
      r.pop();
      return true;
    }

    // 3) Если не на главной вкладке buyer -> вернуть на mainPath
    final path = _currentPath();
    if (r != null && path != widget.mainPath) {
      r.go(widget.mainPath);
      return true;
    }

    // 4) На главной -> двойное нажатие для выхода
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      _showExitSnack();
      return true;
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _onBackPressed,
      child: widget.child,
    );
  }
}
