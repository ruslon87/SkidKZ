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
import 'package:skidkz/features/buyer/screens/product_detail_screen.dart';
import 'package:skidkz/features/buyer/screens/checkout_screen.dart';
import 'package:skidkz/data/models/product.dart';

// seller
import 'package:skidkz/features/seller/screens/seller_shell.dart';
import 'package:skidkz/features/seller/screens/seller_home_screen.dart';
import 'package:skidkz/features/seller/screens/seller_products_screen.dart';
import 'package:skidkz/features/seller/screens/seller_add_product_screen.dart';
import 'package:skidkz/features/seller/screens/seller_orders_screen.dart';

// wanghong
import 'package:skidkz/features/wanghong/screens/wanghong_shell.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_home_screen.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_deals_screen.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_wallet_screen.dart';

// admin — используем новые полноценные экраны
import 'package:skidkz/features/admin/screens/admin_shell.dart';
import 'package:skidkz/features/admin/screens/admin_home_screen.dart';
import 'package:skidkz/features/admin/screens/admin_moderation_screen.dart';
import 'package:skidkz/features/admin/screens/admin_users_screen.dart';
import 'package:skidkz/features/admin/screens/admin_finance_screen.dart';

// info + onboarding
import 'package:skidkz/features/info/screens/seller_info_screen.dart';
import 'package:skidkz/features/info/screens/wanghong_info_screen.dart';
import 'package:skidkz/features/onboarding/screens/buyer_onboarding_screen.dart';
import 'package:skidkz/features/onboarding/screens/seller_onboarding_screen.dart';
import 'package:skidkz/features/onboarding/screens/become_wanghong_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
    _subAuth =
        ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _subUser =
        ref.listen(currentUserDocProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
  late final ProviderSubscription _subAuth;
  late final ProviderSubscription _subUser;

  @override
  void dispose() {
    _subAuth.close();
    _subUser.close();
    super.dispose();
  }
}

// ---------------- Router ----------------

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  bool _isProtectedBuyerPath(String path) {
    if (path.startsWith('/buyer/favorites')) return true;
    if (path.startsWith('/buyer/cart')) return true;
    if (path.startsWith('/buyer/profile')) return true;
    if (path.startsWith('/buyer/orders')) return true;
    return false;
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/buyer/home',
    refreshListenable: refresh,

    redirect: (context, state) async {
      final uri = state.uri;
      final path = uri.path;
      final fullLoc = uri.toString();

      final authAsync = ref.read(authStateChangesProvider);
      final userAsync = ref.read(currentUserDocProvider);

      if (authAsync.isLoading || userAsync.isLoading) return null;

      final fbUser = authAsync.asData?.value;
      final isAuthed = fbUser != null;

      if (path == '/buyer/orders') {
        return '/buyer/profile/orders';
      }

      // Гость -> protected buyer -> login
      if (!isAuthed && _isProtectedBuyerPath(path) && path != '/login') {
        final next = Uri.encodeComponent(fullLoc);
        return '/login?next=$next';
      }

      // login + authed -> вернуть next/кабинет
      if (path == '/login' && isAuthed) {
        final nextRaw = uri.queryParameters['next'];
        final nextDecoded = (nextRaw == null || nextRaw.trim().isEmpty)
            ? null
            : Uri.decodeComponent(nextRaw);

        if (nextDecoded != null && nextDecoded.isNotEmpty) return nextDecoded;
        return '/cabinet';
      }

      // cabinet -> по роли
      if (path == '/cabinet' && isAuthed) {
        final snap = userAsync.asData?.value;
        final data = snap?.data();
        final activeRole = (data?['activeRole'] ?? '').toString();

        switch (activeRole) {
          case 'seller':
            return '/seller/home';
          case 'wanghong':
            return '/wanghong/home';
          case 'admin':
            return '/admin/home';
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
        builder: (context, state) => const SizedBox.shrink(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) {
          final nextRaw = state.uri.queryParameters['next'];
          final next = (nextRaw == null || nextRaw.trim().isEmpty)
              ? null
              : Uri.decodeComponent(nextRaw);

          return LoginScreen(
            nextPath: next,
            action: state.uri.queryParameters['action'],
            productId: state.uri.queryParameters['pid'],
            qty: int.tryParse(state.uri.queryParameters['qty'] ?? ''),
          );
        },
      ),

      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      GoRoute(
        path: '/info/seller',
        builder: (context, state) => const SellerInfoScreen(),
      ),

      GoRoute(
        path: '/info/wanghong',
        builder: (context, state) => const WanghongInfoScreen(),
      ),

      GoRoute(
        path: '/onboarding/buyer',
        builder: (context, state) => BuyerOnboardingScreen(
          nextPath: state.uri.queryParameters['next'],
        ),
      ),

      GoRoute(
        path: '/onboarding/seller',
        builder: (context, state) => const SellerOnboardingScreen(),
      ),

      GoRoute(
        path: '/become-partner',
        builder: (context, state) => const BecomeWanghongScreen(),
      ),

      GoRoute(
        path: '/product-detail',
        builder: (context, state) {
          final product = state.extra as Product?;
          if (product == null) {
            return const Scaffold(
              body: Center(child: Text('Товар не найден')),
            );
          }
          return ProductDetailScreen(product: product);
        },
      ),

      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      GoRoute(
        path: '/buyer/orders',
        redirect: (context, state) => '/buyer/profile/orders',
      ),

      // BUYER tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BuyerRootShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/catalog',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BuyerCatalogScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/favorites',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BuyerFavoritesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/buyer/cart',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BuyerCartScreen()),
              ),
            ],
          ),
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

      // SELLER
      ShellRoute(
        builder: (context, state, child) => SellerShell(child: child),
        routes: [
          GoRoute(
            path: '/seller/home',
            builder: (context, state) => const SellerHomeScreen(),
          ),
          GoRoute(
            path: '/seller/products',
            builder: (context, state) => const SellerProductsScreen(),
          ),
          GoRoute(
            path: '/seller/products/add',
            builder: (context, state) => const SellerAddProductScreen(),
          ),
          GoRoute(
            path: '/seller/products/edit',
            builder: (context, state) {
              final product = state.extra as Product?;
              return SellerAddProductScreen(existingProduct: product);
            },
          ),
          GoRoute(
            path: '/seller/orders',
            builder: (context, state) => const SellerOrdersScreen(),
          ),
        ],
      ),

      // WANGHONG
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

      // ADMIN — новые полноценные экраны
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/home',
            builder: (context, state) => const AdminHomeScreen(),
          ),
          GoRoute(
            path: '/admin/moderation',
            builder: (context, state) => const AdminModerationScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
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
