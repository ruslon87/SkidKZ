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

      // ✅ ЕДИНЫЙ глобальный back:
      // 1) закрыть overlay (drawer/dialog/bottomsheet)
      // 2) если есть router pop -> pop
      // 3) если в buyer и не home -> go home
      // 4) на home -> double back exit
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

  bool _isBuyerPath(String path) => path.startsWith('/buyer/');

  Uri _currentUri() => widget.router.routeInformationProvider.value.uri;

  Future<void> _onBack() async {
    // 1) закрыть верхний overlay (drawer/dialog/bottomsheet)
    final nav = r.rootNavigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }

    // 2) если есть pop по go_router-стеку -> pop
    if (widget.router.canPop()) {
      widget.router.pop();
      return;
    }

    // 3) если мы на /login без истории (пришли редиректом),
    //    то "назад" = уйти на next или на /buyer/home
    final uri = _currentUri();
    final path = uri.path;

    if (path == '/login') {
      final nextRaw = uri.queryParameters['next'];
      final next = (nextRaw == null || nextRaw.trim().isEmpty)
          ? null
          : Uri.decodeComponent(nextRaw);
      widget.router.go(next ?? '/buyer/home');
      return;
    }

    // 4) buyer: не home -> go home
    if (_isBuyerPath(path) && path != '/buyer/home') {
      widget.router.go('/buyer/home');
      return;
    }

    // 5) double back = exit
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
