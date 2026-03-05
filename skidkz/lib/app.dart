// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart' as r;
import 'core/theme/app_theme.dart';

class SkidKZApp extends ConsumerWidget {
  const SkidKZApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(r.routerProvider);

    return MaterialApp.router(
      title: 'SkidKZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,

      // Глобальный back-guard: закрывает overlay (drawer/dialog),
      // возвращает на /buyer/home, и только потом double-back = exit.
      builder: (context, child) {
        return _GlobalBackGuard(
          router: router,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _GlobalBackGuard extends StatefulWidget {
  const _GlobalBackGuard({
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<_GlobalBackGuard> createState() => _GlobalBackGuardState();
}

class _GlobalBackGuardState extends State<_GlobalBackGuard> {
  DateTime? _lastBack;

  String _currentPath() {
    // ✅ go_router 17: достаём текущий URI через routeInformationProvider
    final uri = widget.router.routeInformationProvider.value.uri;
    final path = uri.path.trim();

    // ✅ ВАЖНО: на самом старте иногда бывает "/" или пусто — трактуем как home
    if (path.isEmpty || path == '/') return '/buyer/home';

    return path;
  }

  bool _isBuyerPath(String path) => path.startsWith('/buyer/');

  void _toastExitHint() {
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

  Future<void> _onBack() async {
    // 1) Сначала закрываем overlay уровнем Navigator (drawer/dialog/bottomsheet)
    // Это важно, чтобы back при открытом drawer НЕ закрывал приложение.
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
      return;
    }

    // 2) Если go_router имеет историю (push-экраны) — делаем pop
    if (widget.router.canPop()) {
      widget.router.pop();
      return;
    }

    // 3) Если мы в buyer-зоне и не на home — уходим на home вместо выхода
    final path = _currentPath();
    if (_isBuyerPath(path) && path != '/buyer/home') {
      widget.router.go('/buyer/home');
      return;
    }

    // 4) На корне (включая первый запуск): ТОЛЬКО double back = exit
    final now = DateTime.now();
    if (_lastBack == null || now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      _toastExitHint();
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBack();
      },
      child: widget.child,
    );
  }
}
