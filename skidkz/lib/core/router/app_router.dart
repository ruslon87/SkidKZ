// lib/core/router/app_router.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/features/admin/screens/admin_shell.dart';
import 'package:skidkz/features/auth/screens/login_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_cart_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_catalog_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_favorites_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_orders_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_profile_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_shell.dart';
import 'package:skidkz/features/home/screens/home_screen.dart';
import 'package:skidkz/features/info/screens/seller_info_screen.dart';
import 'package:skidkz/features/info/screens/wanghong_info_screen.dart';
import 'package:skidkz/features/onboarding/screens/buyer_onboarding_screen.dart';
import 'package:skidkz/features/seller/screens/seller_products_screen.dart';
import 'package:skidkz/features/seller/screens/seller_orders_screen.dart';
import 'package:skidkz/features/seller/screens/seller_shell.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_shell.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_home_screen.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_deals_screen.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_wallet_screen.dart';

/// ------------- Auth / User providers -------------

final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return fb.FirebaseAuth.instance.authStateChanges();
});

final currentUserDocProvider = FutureProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) return null;

  return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
});

/// ------------- GoRouter provider -------------

final routerProvider = Provider<GoRouter>((ref) {
  // чтобы GoRouter пересобирался при смене auth
  final authValue = ref.watch(authStateChangesProvider);

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: '/buyer/home',
    refreshListenable: GoRouterRefreshStream(
      fb.FirebaseAuth.instance.authStateChanges(),
    ),

    redirect: (BuildContext context, GoRouterState state) async {
      final loc = state.uri.toString(); // включая query
      final path = state.uri.path;

      // current user
      fb.User? user;
      try {
        user = await ref.read(authStateChangesProvider.future);
      } catch (_) {
        user = fb.FirebaseAuth.instance.currentUser;
      }
      final isAuthed = user != null;

      // ---- PROTECTED buyer paths (guest -> login?next=...) ----
      bool isProtectedBuyerPath(String p) {
        // вкладки
        if (p.startsWith('/buyer/favorites')) return true;
        if (p.startsWith('/buyer/cart')) return true;
        if (p.startsWith('/buyer/profile')) return true;

        // алиас
        if (p.startsWith('/buyer/orders')) return true;

        return false;
      }

      // если гость пытается попасть в защищённые разделы buyer → login с next
      if (!isAuthed && isProtectedBuyerPath(path) && !path.startsWith('/login')) {
        final next = Uri.encodeComponent(loc);
        return '/login?next=$next';
      }

      // если мы уже на /login и юзер залогинился — уводим по next (если есть)
      if (path == '/login' && isAuthed) {
        final next = state.uri.queryParameters['next'];
        if (next != null && next.trim().isNotEmpty) {
          final decoded = Uri.decodeComponent(next);
          return decoded;
        }
        return '/buyer/home';
      }

      // алиас /buyer/orders -> /buyer/profile/orders (чтобы было внутри профиля-ветки)
      if (path == '/buyer/orders') {
        return '/buyer/profile/orders';
      }

      // /cabinet — выбор кабинета по activeRole (если понадобится)
      if (path == '/cabinet') {
        if (!isAuthed) return '/buyer/home';

        final snap = await ref.read(currentUserDocProvider.future);
        final data = snap?.data();
        final activeRole = (data?['activeRole'] ?? '').toString();

        if (activeRole == 'seller') return '/seller/products';
        if (activeRole == 'wanghong') return '/wanghong/home';
        if (activeRole == 'admin') return '/admin/moderation';

        return '/buyer/home';
      }

      return null;
    },

    routes: [
      /// ---------- BUYER (5 tabs) ----------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BuyerRootShell(navigationShell: navigationShell);
        },
        branches: [
          // 0) Магазин
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // 1) Каталог
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/catalog',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BuyerCatalogScreen(),
                ),
              ),
            ],
          ),

          // 2) Избранное (protected)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/favorites',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BuyerFavoritesScreen(),
                ),
              ),
            ],
          ),

          // 3) Корзина (protected)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/cart',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BuyerCartScreen(),
                ),
              ),
            ],
          ),

          // 4) Профиль (protected) + вложенные экраны
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: BuyerProfileScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const BuyerOrdersScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      /// ---------- AUTH ----------
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final next = state.uri.queryParameters['next'];
          final nextDecoded =
              (next == null || next.trim().isEmpty) ? null : Uri.decodeComponent(next);
          return LoginScreen(nextPath: nextDecoded);
        },
      ),

      /// ---------- Buyer onboarding (если используешь) ----------
      GoRoute(
        path: '/buyer/onboarding',
        builder: (context, state) {
          final next = state.uri.queryParameters['next'];
          final nextDecoded =
              (next == null || next.trim().isEmpty) ? null : Uri.decodeComponent(next);
          return BuyerOnboardingScreen(nextPath: nextDecoded);
        },
      ),

      /// ---------- ALIAS (если кто-то ещё где-то пушит /buyer/orders) ----------
      GoRoute(
        path: '/buyer/orders',
        redirect: (context, state) => '/buyer/profile/orders',
      ),

      /// ---------- CABINET SELECTOR ----------
      GoRoute(
        path: '/cabinet',
        builder: (context, state) => const SizedBox.shrink(),
      ),

      /// ---------- INFO (public stubs) ----------
      GoRoute(
        path: '/info/seller',
        builder: (context, state) => const SellerInfoScreen(),
      ),
      GoRoute(
        path: '/info/wanghong',
        builder: (context, state) => const WanghongInfoScreen(),
      ),

      /// ---------- SELLER ----------
      ShellRoute(
        builder: (context, state, child) => SellerShell(child: child),
        routes: [
          GoRoute(
            path: '/seller/products',
            builder: (context, state) => const SellerProductsScreen(),
          ),
          GoRoute(
            path: '/seller/orders',
            builder: (context, state) => const SellerOrdersScreen(),
          ),
        ],
      ),

      /// ---------- WANGHONG ----------
      ShellRoute(
        builder: (context, state, child) => WanghongShell(child: child),
        routes: [
          GoRoute(
            path: '/wanghong/home',
            builder: (context, state) => const WanghongHomeScreen(),
          ),
          GoRoute(
            path: '/wanghong/deals',
            builder: (context, state) => const WanghongDealsScreen(),
          ),
          GoRoute(
            path: '/wanghong/wallet',
            builder: (context, state) => const WanghongWalletScreen(),
          ),
        ],
      ),

      /// ---------- ADMIN ----------
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/moderation',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/admin/finance',
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      ),
    ],
  );
});

/// ------------- helpers -------------

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
