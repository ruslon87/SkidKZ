// lib/core/router/app_router.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// auth
import 'package:skidkz/features/auth/screens/login_screen.dart';
import 'package:skidkz/features/auth/screens/role_selection_screen.dart';

// buyer
import 'package:skidkz/features/buyer/screens/buyer_shell.dart';
import 'package:skidkz/features/home/home_page.dart';
import 'package:skidkz/features/buyer/screens/buyer_catalog_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_favorites_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_cart_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_profile_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_orders_screen.dart';

// seller
import 'package:skidkz/features/seller/screens/seller_shell.dart';
import 'package:skidkz/features/seller/screens/seller_products_screen.dart';
import 'package:skidkz/features/seller/screens/seller_add_product_screen.dart';
import 'package:skidkz/features/seller/screens/seller_orders_screen.dart';

// wanghong
import 'package:skidkz/features/wanghong/screens/wanghong_shell.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_home_screen.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_deals_screen.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_wallet_screen.dart';

// admin
import 'package:skidkz/features/admin/screens/admin_shell.dart';
import 'package:skidkz/features/admin/screens/moderation_screen.dart';
import 'package:skidkz/features/admin/screens/users_screen.dart';
import 'package:skidkz/features/admin/screens/admin_finance_screen.dart';

// info + onboarding
import 'package:skidkz/features/info/screens/seller_info_screen.dart';
import 'package:skidkz/features/info/screens/wanghong_info_screen.dart';
import 'package:skidkz/features/onboarding/screens/buyer_onboarding_screen.dart';

// ---------------- Providers ----------------

final firebaseAuthProvider =
    Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserDocProvider =
    FutureProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) async {
  final fbUser = await ref.watch(authStateChangesProvider.future);
  if (fbUser == null) return null;

  final db = ref.watch(firestoreProvider);
  final docRef = db.collection('users').doc(fbUser.uid);
  return docRef.get();
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _subAuth = ref.listen<AsyncValue<fb.User?>>(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
    );
    _subUser = ref.listen<AsyncValue<DocumentSnapshot<Map<String, dynamic>>?>>(
      currentUserDocProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref ref;
  late final ProviderSubscription<AsyncValue<fb.User?>> _subAuth;
  late final ProviderSubscription<AsyncValue<DocumentSnapshot<Map<String, dynamic>>?>> _subUser;

  @override
  void dispose() {
    _subAuth.close();
    _subUser.close();
    super.dispose();
  }
}

// ---------------- Navigator Keys ----------------

// ✅ ВАЖНО: всё модальное/логин/инфо открываем в ROOT navigator
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ✅ Для buyer StatefulShellRoute нужен свой navigator, чтобы он не мешал root
final _buyerShellNavigatorKey = GlobalKey<NavigatorState>();

// ---------------- Router ----------------

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  bool _isProtectedBuyerPath(String path) {
    // ВАЖНО: табы мы защищаем в BuyerRootShell (через push(login)).
    // Но deep-link/прямой заход сюда всё равно должен требовать логин.
    if (path.startsWith('/buyer/favorites')) return true;
    if (path.startsWith('/buyer/cart')) return true;
    if (path.startsWith('/buyer/profile')) return true;

    // алиас
    if (path.startsWith('/buyer/orders')) return true;

    return false;
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/buyer/home',
    refreshListenable: refresh,
    debugLogDiagnostics: false,

    redirect: (context, state) async {
      final uri = state.uri;
      final path = uri.path;
      final fullLoc = uri.toString(); // path + query

      final authAsync = ref.read(authStateChangesProvider);
      final userAsync = ref.read(currentUserDocProvider);

      // пока грузится — не редиректим
      if (authAsync.isLoading || userAsync.isLoading) return null;

      final fbUser = authAsync.asData?.value;
      final isAuthed = fbUser != null;

      // 1) алиас /buyer/orders -> /buyer/profile/orders
      if (path == '/buyer/orders') {
        return '/buyer/profile/orders';
      }

      // 2) гость идет в защищенные buyer-экраны -> /login?next=...
      // ВАЖНО: /login сам по себе не редиректим
      if (!isAuthed && _isProtectedBuyerPath(path) && path != '/login') {
        final next = Uri.encodeComponent(fullLoc);
        return '/login?next=$next';
      }

      // 3) если мы на /login и уже залогинились — уводим на next или в кабинет
      if (path == '/login' && isAuthed) {
        final nextRaw = uri.queryParameters['next'];
        final nextDecoded = (nextRaw == null || nextRaw.trim().isEmpty)
            ? null
            : Uri.decodeComponent(nextRaw);

        if (nextDecoded != null && nextDecoded.isNotEmpty) return nextDecoded;
        return '/cabinet';
      }

      // 4) /cabinet — разруливаем по activeRole
      if (path == '/cabinet' && isAuthed) {
        final snap = userAsync.asData?.value;
        final data = snap?.data();
        final activeRole = (data?['activeRole'] ?? '').toString();

        switch (activeRole) {
          case 'seller':
            return '/seller/products';
          case 'wanghong':
            return '/wanghong/home';
          case 'admin':
            return '/admin/moderation';
          default:
            return '/buyer/home';
        }
      }

      return null;
    },

    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/buyer/home'),

      GoRoute(
        path: '/cabinet',
        // технический маршрут, сюда всегда попадём через redirect
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SizedBox.shrink(),
        ),
      ),

      // ✅ ЛОГИН — обязательно в ROOT navigator
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        pageBuilder: (context, state) {
          final nextRaw = state.uri.queryParameters['next'];
          final nextDecoded = (nextRaw == null || nextRaw.trim().isEmpty)
              ? null
              : Uri.decodeComponent(nextRaw);

          return MaterialPage(
            key: state.pageKey,
            child: LoginScreen(nextPath: nextDecoded),
          );
        },
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/role-select',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RoleSelectionScreen(),
        ),
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/info/seller',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SellerInfoScreen(),
        ),
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/info/wanghong',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const WanghongInfoScreen(),
        ),
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding/buyer',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BuyerOnboardingScreen(
            nextPath: state.uri.queryParameters['next'],
          ),
        ),
      ),

      // алиас (на случай, если где-то еще в коде пушится /buyer/orders)
      GoRoute(
        path: '/buyer/orders',
        redirect: (context, state) => '/buyer/profile/orders',
      ),

      // -------- BUYER: 5 вкладок через indexedStack --------
      StatefulShellRoute.indexedStack(
        navigatorContainerBuilder: (context, navigationShell, children) {
          // можно оставить дефолт, но ключ контейнера важен для разруливания навигации
          return navigationShell;
        },
        parentNavigatorKey: _rootNavigatorKey,
        navigatorKey: _buyerShellNavigatorKey,
        builder: (context, state, navigationShell) {
          return BuyerRootShell(navigationShell: navigationShell);
        },
        branches: [
          // 0) Магазин
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),

          // 1) Каталог
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/catalog',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BuyerCatalogScreen()),
              ),
            ],
          ),

          // 2) Избранное (protected)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/favorites',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BuyerFavoritesScreen()),
              ),
            ],
          ),

          // 3) Корзина (protected)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/cart',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BuyerCartScreen()),
              ),
            ],
          ),

          // 4) Профиль (protected) + вложенные
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BuyerProfileScreen()),
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

      // -------- SELLER --------
      ShellRoute(
        builder: (context, state, child) => SellerShell(child: child),
        routes: [
          GoRoute(
            path: '/seller/products',
            builder: (context, state) => const SellerProductsScreen(),
          ),
          GoRoute(
            path: '/seller/products/add',
            builder: (context, state) => const SellerAddProductScreen(),
          ),
          GoRoute(
            path: '/seller/orders',
            builder: (context, state) => const SellerOrdersScreen(),
          ),
        ],
      ),

      // -------- WANGHONG --------
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

      // -------- ADMIN --------
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/moderation',
            builder: (context, state) => const ModerationScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/finance',
            builder: (context, state) => const AdminFinanceScreen(),
          ),
        ],
      ),
    ],
  );
});
