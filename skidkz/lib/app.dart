// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart' as r;
import 'core/theme/app_theme.dart';

class SkidKZApp extends ConsumerStatefulWidget {
  const SkidKZApp({super.key});

  @override
  ConsumerState<SkidKZApp> createState() => _SkidKZAppState();
}

class _SkidKZAppState extends ConsumerState<SkidKZApp> {
  late final _SkidBackButtonDispatcher _backDispatcher;

  @override
  void initState() {
    super.initState();

    _backDispatcher = _SkidBackButtonDispatcher(
      getRouter: () => ref.read(r.routerProvider),
      getContext: () => r.rootNavigatorKey.currentContext,
      getNavigatorState: () => r.rootNavigatorKey.currentState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(r.routerProvider);

    return MaterialApp.router(
      title: 'SkidKZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      backButtonDispatcher: _backDispatcher,
    );
  }
}

class _SkidBackButtonDispatcher extends RootBackButtonDispatcher {
  _SkidBackButtonDispatcher({
    required this.getRouter,
    required this.getContext,
    required this.getNavigatorState,
  });

  final GoRouter Function() getRouter;
  final BuildContext? Function() getContext;
  final NavigatorState? Function() getNavigatorState;

  DateTime? _lastBack;

  String _normalizePath(String path) {
    final p = path.trim();
    if (p.isEmpty || p == '/') return '/buyer/home';
    return p;
  }

  bool _isBuyerRootTab(String path) {
    return path == '/buyer/home' ||
        path == '/buyer/catalog' ||
        path == '/buyer/favorites' ||
        path == '/buyer/cart' ||
        path == '/buyer/profile';
  }

  void _showExitHint() {
    final ctx = getContext();
    if (ctx == null) return;

    final messenger = ScaffoldMessenger.maybeOf(ctx);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<bool> _handleHomeExit() async {
    final now = DateTime.now();

    if (_lastBack == null ||
        now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      _showExitHint();
      return true;
    }

    await SystemNavigator.pop();
    return true;
  }

  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) async {
    final router = getRouter();
    final nav = getNavigatorState();

    // 1) Сначала пробуем закрыть overlay / drawer / dialog / bottom sheet
    if (nav != null) {
      final didPopOverlay = await nav.maybePop();
      if (didPopOverlay) return true;
    }

    final path =
        _normalizePath(router.routeInformationProvider.value.uri.path);

    // 2) Если есть реальный pop в router-стеке, отдаём обработку роутеру
    if (router.canPop()) {
      return await super.invokeCallback(defaultValue);
    }

    // 3) Корневые buyer-вкладки обрабатываем жёстко сами
    if (_isBuyerRootTab(path)) {
      if (path == '/buyer/home') {
        return await _handleHomeExit();
      }

      router.go('/buyer/home');
      return true;
    }

    // 4) Всё остальное отдаём стандартной роутер-логике
    return await super.invokeCallback(defaultValue);
  }
}
