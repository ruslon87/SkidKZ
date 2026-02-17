// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/location/location_controller.dart';
import 'core/widgets/app_back_handler.dart';

class SkidKZApp extends ConsumerStatefulWidget {
  const SkidKZApp({super.key});

  @override
  ConsumerState<SkidKZApp> createState() => _SkidKZAppState();
}

class _SkidKZAppState extends ConsumerState<SkidKZApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationControllerProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SkidKZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      scaffoldMessengerKey: _messengerKey,

      // ВАЖНО: AppBackHandler теперь внутри дерева Router
      builder: (context, child) {
        return AppBackHandler(
          router: router,
          messengerKey: _messengerKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
