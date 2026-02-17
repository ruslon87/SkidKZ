// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_back_handler.dart';

class SkidKZApp extends ConsumerWidget {
  const SkidKZApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    return MaterialApp.router(
      title: 'SkidKZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      scaffoldMessengerKey: messengerKey,
      builder: (context, child) {
        return AppBackHandler(
          router: router,
          messengerKey: messengerKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
