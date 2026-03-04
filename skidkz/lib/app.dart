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

      // ✅ глобальный back: закрываем overlay -> возвращаем на /buyer/home -> double back
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

  bool _isBuyerLocation(String loc) => loc.startsWith('/buyer/');

  Future<void> _onBack() async {
    // 1) сначала пробуем закрыть drawer/dialog/bottomsheet (через root navigator)
    final nav = r.rootNavigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }

    // 2) если есть история go_router — pop
    if (widget.router.canPop()) {
      widget.router.pop();
      return;
    }

    final loc = widget.router.routerDelegate.currentConfiguration.fullPath ??
        widget.router.location;

    // 3) если мы в buyer и не на home — возвращаем на home (вместо закрытия приложения)
    if (_isBuyerLocation(loc) && loc != '/buyer/home') {
      widget.router.go('/buyer/home');
      return;
    }

    // 4) double back = exit (и на /buyer/home, и в других root-местах)
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
