// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_back_handler.dart';
import 'core/location/location_controller.dart';

class SkidKZApp extends ConsumerStatefulWidget {
  const SkidKZApp({super.key});

  @override
  ConsumerState<SkidKZApp> createState() => _SkidKZAppState();
}

class _SkidKZAppState extends ConsumerState<SkidKZApp> {
  @override
  void initState() {
    super.initState();
    // Запуск определения города при старте (вариант B)
    Future.microtask(() {
      ref.read(locationControllerProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(routerProvider);

    return AppBackHandler(
      router: router,
      child: MaterialApp.router(
        title: 'SkidKZ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    );
  }
}
