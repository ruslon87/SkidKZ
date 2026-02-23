// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cabinet/cabinet_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/buyer/screens/buyer_shell.dart';
import '../../features/seller/screens/seller_shell.dart';
import '../../features/wanghong/screens/wanghong_shell.dart';
import '../../features/admin/screens/admin_shell.dart';

/// Минимальный routerProvider, чтобы проект собирался и навигация работала.
/// Дальше можно наращивать guards/redirect по auth+role.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/cabinet',
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/cabinet',
        builder: (context, state) => const CabinetScreen(),
      ),

      // Role shells
      GoRoute(
        path: '/buyer',
        redirect: (context, state) => '/buyer/home',
      ),
      GoRoute(
        path: '/buyer/home',
        builder: (context, state) => const BuyerShell(),
      ),

      GoRoute(
        path: '/seller',
        redirect: (context, state) => '/seller/products',
      ),
      GoRoute(
        path: '/seller/products',
        builder: (context, state) => const SellerShell(),
      ),

      GoRoute(
        path: '/wanghong',
        redirect: (context, state) => '/wanghong/home',
      ),
      GoRoute(
        path: '/wanghong/home',
        builder: (context, state) => const WanghongShell(),
      ),

      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/moderation',
      ),
      GoRoute(
        path: '/admin/moderation',
        builder: (context, state) => const AdminShell(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.uri}'),
      ),
    ),
  );
});
