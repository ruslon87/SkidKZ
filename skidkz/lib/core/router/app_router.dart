// lib/core/router/app_router.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/data/models/user_model.dart';

import 'package:skidkz/features/auth/screens/login_screen.dart';
import 'package:skidkz/features/auth/screens/role_selection_screen.dart';

import 'package:skidkz/features/buyer/screens/buyer_shell.dart';
import 'package:skidkz/features/home/home_page.dart';
import 'package:skidkz/features/buyer/screens/buyer_catalog_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_favorites_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_cart_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_profile_screen.dart';

import 'package:skidkz/features/seller/screens/seller_shell.dart';
import 'package:skidkz/features/seller/screens/seller_products_screen.dart';
import 'package:skidkz/features/seller/screens/seller_add_product_screen.dart';
import 'package:skidkz/features/seller/screens/seller_orders_screen.dart';

import 'package:skidkz/features/wanghong/screens/wanghong_shell.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_home_screen.dart';

import 'package:skidkz/features/admin/screens/admin_shell.dart';
import 'package:skidkz/features/admin/screens/moderation_screen.dart';
import 'package:skidkz/features/admin/screens/users_screen.dart';
import 'package:skidkz/features/admin/screens/admin_finance_screen.dart';

/// --------------------
/// Firebase singletons
/// --------------------
final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// --------------------
/// Auth stream provider
/// --------------------
final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// --------------------
/// Active role provider
/// users/{uid}.activeRole -> "buyer"|"wanghong"|"seller"|"admin"
/// --------------------
final activeRoleProvider = FutureProvider<UserRole?>((ref) async {
  final fbUser = await ref.watch(authStateChangesProvider.future);
  if (fbUser == null) return null;

  final db = ref.watch(firestoreProvider);
  final doc = await db.collection('users').doc(fbUser.uid).get();
  if (!doc.exists) return null;

  final data = doc.data();
  final roleStr = data?['activeRole'] as String?;
  if (roleStr == null) return null;

  return UserRole.values.firstWhere(
    (r) => r.name == roleStr,
    orElse: () => UserRole.buyer,
  );
});

/// --------------------
/// Router refresh helper
/// --------------------
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _subAuth = ref.listen<AsyncValue<fb.User?>>(authStateChangesProvider, (_, __) {
      notifyListeners();
    });
    _subRole = ref.listen<AsyncValue<UserRole?>>(activeRoleProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
  late final ProviderSubscription<AsyncValue<fb.User?>> _subAuth;
  late final ProviderSubscription<AsyncValue<UserRole?>> _subRole;

  @override
  void dispose() {
    _subAuth.close();
    _subRole.close();
    super.dispose();
  }
}

bool _isBuyerArea(String location) {
  return location == '/' || location.startsWith('/buyer');
}

bool _isCabinetArea(String location) {
  return location == '/cabinet' ||
      location == '/login' ||
      location == '/role-select' ||
      location.startsWith('/seller') ||
      location.startsWith('/wanghong') ||
      location.startsWith('/admin');
}

String _homeForRole(UserRole role) {
  switch (role) {
    case UserRole.buyer:
      return '/buyer/home';
    case UserRole.wanghong:
      return '/wanghong/home';
    case UserRole.seller:
      return '/seller/products';
    case UserRole.admin:
      return '/admin/moderation';
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/buyer/home',
    refreshListenable: refresh,

    redirect: (context, state) {
      final location = state.uri.toString();

      final authAsync = ref.read(authStateChangesProvider);
      final roleAsync = ref.read(activeRoleProvider);

      final fbUser = authAsync.asData?.value;
      final activeRole = roleAsync.asData?.value;

      final isLoading = authAsync.isLoading || roleAsync.isLoading;

      final isLogin = location == '/login';
      final isRoleSelect = location == '/role-select';

      // Пока грузимся — не редиректим, иначе будет "дребезг"
      if (isLoading) return null;

      // -----------------------------
      // 1) Public buyer area: always ok
      // -----------------------------
      if (_isBuyerArea(location)) {
        // Покупательские экраны публичны (без логина)
        return null;
      }

      // -----------------------------
      // 2) Cabinet area access control
      // -----------------------------
      if (_isCabinetArea(location)) {
        // Не залогинен -> кабинет только через /login
        if (fbUser == null) {
          return isLogin ? null : '/login';
        }

        // Залогинен -> /login больше не нужен
        if (isLogin) {
          return '/cabinet';
        }

        // /cabinet -> либо role-select, либо кабинет по роли
        if (location == '/cabinet') {
          if (activeRole == null) return '/role-select';
          return _homeForRole(activeRole);
        }

        // /role-select: если роль уже есть — сразу в кабинет по роли
        if (isRoleSelect) {
          if (activeRole == null) return null;
          return _homeForRole(activeRole);
        }

        // Если роль еще не выбрана, а он лезет в seller/wanghong/admin -> отправляем выбирать роль
        if (activeRole == null &&
            (location.startsWith('/seller') || location.startsWith('/wanghong') || location.startsWith('/admin'))) {
          return '/role-select';
        }

        // На MVP: если роль выбрана, но пользователь пытается открыть чужую зону — можно запретить.
        // ЖЕСТКИЙ контроль (рекомендую включить):
        if (activeRole != null) {
          if (location.startsWith('/seller') && activeRole != UserRole.seller) return _homeForRole(activeRole);
          if (location.startsWith('/wanghong') && activeRole != UserRole.wanghong) return _homeForRole(activeRole);
          if (location.startsWith('/admin') && activeRole != UserRole.admin) return _homeForRole(activeRole);
        }

        return null;
      }

      // -----------------------------
      // fallback: if unknown route
      // -----------------------------
      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(child: Text(state.error.toString())),
    ),

    routes: [
      /// -------------------------
      /// AUTH / CABINET ENTRY
      /// -------------------------
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/cabinet',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),

      /// -------------------------
      /// BUYER (PUBLIC) SHELL
      /// -------------------------
      ShellRoute(
        builder: (context, state, child) => BuyerShell(child: child),
        routes: [
          GoRoute(
            path: '/buyer/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/buyer/catalog',
            builder: (context, state) => const BuyerCatalogScreen(),
          ),
          GoRoute(
            path: '/buyer/favorites',
            builder: (context, state) => const BuyerFavoritesScreen(),
          ),
          GoRoute(
            path: '/buyer/cart',
            builder: (context, state) => const BuyerCartScreen(),
          ),
          GoRoute(
            path: '/buyer/profile',
            builder: (context, state) => const BuyerProfileScreen(),
          ),
        ],
      ),

      /// -------------------------
      /// SELLER (AUTH REQUIRED)
      /// -------------------------
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

      /// -------------------------
      /// WANGHONG (AUTH REQUIRED)
      /// -------------------------
      ShellRoute(
        builder: (context, state, child) => WanghongShell(child: child),
        routes: [
          GoRoute(
            path: '/wanghong/home',
            builder: (context, state) => const WanghongHomeScreen(),
          ),
        ],
      ),

      /// -------------------------
      /// ADMIN (AUTH REQUIRED)
      /// -------------------------
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