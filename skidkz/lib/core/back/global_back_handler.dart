import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class GlobalBackHandler extends StatefulWidget {
  const GlobalBackHandler({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<GlobalBackHandler> createState() => _GlobalBackHandlerState();
}

class _GlobalBackHandlerState extends State<GlobalBackHandler> {
  DateTime? _lastBackPress;

  bool _isMain(String path) {
    return path == '/buyer/home' ||
        path == '/seller/products' ||
        path == '/wanghong/home' ||
        path == '/admin/moderation';
  }

  String _mainFor(String path) {
    if (path.startsWith('/seller')) return '/seller/products';
    if (path.startsWith('/wanghong')) return '/wanghong/home';
    if (path.startsWith('/admin')) return '/admin/moderation';
    return '/buyer/home';
  }

  Future<bool> _onBack() async {
    final router = widget.router;
    final path = router.routeInformationProvider.value.uri.path;

    if (router.canPop()) {
      router.pop();
      return true;
    }

    if (_isMain(path)) {
      final now = DateTime.now();
      if (_lastBackPress == null ||
          now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
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

    router.go(_mainFor(path));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _onBack,
      child: widget.child,
    );
  }
}
