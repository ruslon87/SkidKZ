// lib/core/router/app_router.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/data/models/user_model.dart';

import 'package:skidkz/features/auth/screens/login_screen.dart';
import 'package:skidkz/features/auth/screens/role_selection_screen.dart';

import 'package:skidkz/features/buyer/screens/buyer_shell.dart';
import 'package:skidkz/features/buyer/screens/catalog_screen.dart';
import 'package:skidkz/features/buyer/screens/product_detail_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_orders_screen.dart';

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

import 'package:skidkz/features/buyer/screens/buyer_catalog_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_favorites_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_cart_screen.dart';
import 'package:skidkz/features/buyer/screens/buyer_profile_screen.dart';

/// --- Firebase singletons ---
final firebaseAuthProvider =
    Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Auth stream
final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// users/{uid} realtime snapshot (null если не залогинен)
final userDocProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final db = ref.watch(firestoreProvider);

  return auth.authStateChanges().asyncExpand((u) {
    if (u == null) {
      return Stream.value(null);
    }
    return db.collection('users').doc(u.uid).snapshots();
  });
});

/// ActiveRole из users/{uid}.activeRole или users/{uid}.role (fallback)
final activeRoleProvider = Provider<UserRole?>((ref) {
  final snapAsync = ref.watch(userDocProvider);
  final snap = snapAsync.asData?.value;

  if (snap == null || !snap.exists) return null;

  final data = snap.data();
  if (data == null) return null;

  final roleStr = (data['activeRole'] as String?) ?? (data['role'] as String?);
  if (roleStr == null) return null;

  return UserRole.values.firstWhere(
    (r) => r.name == roleStr,
    orElse: () => UserRole.buyer,
  );
});

/// Router refresh helper
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _sub1 = ref.listen<AsyncValue<fb.User?>>(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
    );

    _sub2 = ref.listen<AsyncValue<DocumentSnapshot<Map<String, dynamic>>?>>(
      userDocProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref ref;
  late final ProviderSubscription<AsyncValue<fb.User?>> _sub1;
  late final ProviderSubscription<
      AsyncValue<DocumentSnapshot<Map<String, dynamic>>?>> _sub2;

  @override
  void dispose() {
    _sub1.close();
    _sub2.close();
    super.dispose();
  }
}

bool _isCabinetArea(String location) {
  return location.startsWith('/seller') ||
      location.startsWith('/wanghong') ||
      location.startsWith('/admin') ||
      location == '/role-select' ||
      location == '/cabinet';
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
    // Витрина — стартовая
    initialLocation: '/buyer/home',
    refreshListenable: refresh,

    redirect: (context, state) {
      final location = state.uri.toString();

      // Публичная часть покупателя без логина
      final isPublicBuyer = location.startsWith('/buyer') ||
          location == '/' ||
          location.isEmpty;

      final authAsync = ref.read(authStateChangesProvider);
      final fbUser = authAsync.asData?.value;

      // Роль читаем из стрима users/{uid}
      final role = ref.read(activeRoleProvider);

      final userDocAsync = ref.read(userDocProvider);

      final isLoading = authAsync.isLoading || userDocAsync.isLoading;

      final isLogin = location == '/login';
      final isRoleSelect = location == '/role-select';

      // Пока грузится — не дёргаем редиректы
      if (isLoading) return null;

      // 1) Не залогинен
      if (fbUser == null) {
        if (isPublicBuyer) return null;
        // Любая кабинетная зона требует логин
        return isLogin ? null : '/login';
      }

      // 2) Залогинен — /login больше не нужен
      if (isLogin) {
        return '/cabinet';
      }

      // 3) Кабинетная зона
      if (_isCabinetArea(location)) {
        // Роль не задана -> выбор роли
        if (role == null) {
          return isRoleSelect ? null : '/role-select';
        }

        // /role-select при уже заданной роли -> домой
        if (isRoleSelect) {
          return _homeForRole(role);
        }

        // /cabinet -> домой по роли
        if (location == '/cabinet') {
          return _homeForRole(role);
        }
      }

      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(child: Text(state.error.toString())),
    ),

    routes: [
      // LOGIN + ROLE SELECT
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Технический вход в кабинет
      GoRoute(
        path: '/cabinet',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),

      // BUYER (публично)
      ShellRoute(
        builder: (context, state, child) => BuyerShell(child: child),
        routes: [
          GoRoute(
            path: '/buyer/home',
            builder: (context, state) => const CatalogScreen(),
          ),
          GoRoute(
            path: '/buyer/orders',
            builder: (context, state) => const BuyerOrdersScreen(),
          ),
          GoRoute(
            path: '/buyer/product/:id',
            builder: (context, state) => ProductDetailScreen(
              productId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // SELLER
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

      // WANGHONG
      ShellRoute(
        builder: (context, state, child) => WanghongShell(child: child),
        routes: [
          GoRoute(
            path: '/wanghong/home',
            builder: (context, state) => const WanghongHomeScreen(),
          ),
        ],
      ),

      // ADMIN
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
