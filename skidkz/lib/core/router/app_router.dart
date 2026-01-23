import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

/// --- Firebase providers ---
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Текущее состояние авторизации (стрим).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Роль пользователя из Firestore (может быть null если профиль не создан).
final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) return null;

  final db = ref.watch(firestoreProvider);
  final snap = await db.collection('users').doc(user.uid).get();
  if (!snap.exists) return null;

  final data = snap.data();
  final roleStr = data?['role'] as String?;
  if (roleStr == null) return null;

  // role хранится строкой: buyer/wanghong/seller/admin
  return UserRole.values.firstWhere(
    (e) => e.name == roleStr,
    orElse: () => UserRole.buyer,
  );
});

/// Listenable для refreshListenable (обновляет роутер при изменениях auth/role)
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _sub1 = ref.listen<User?>(authStateChangesProvider.select((v) => v.valueOrNull), (_, __) {
      notifyListeners();
    });

    _sub2 = ref.listen<AsyncValue<UserRole?>>(userRoleProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
  late final ProviderSubscription _sub1;
  late final ProviderSubscription _sub2;

  @override
  void dispose() {
    _sub1.close();
    _sub2.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,

    redirect: (context, state) {
      final location = state.uri.toString();

      final authAsync = ref.read(authStateChangesProvider);
      final user = authAsync.valueOrNull;

      final roleAsync = ref.read(userRoleProvider);
      final role = roleAsync.valueOrNull;

      final isLogin = location == '/login';
      final isRoleSelect = location == '/role-select';

      // Пока грузится auth/role — не дёргаем редиректы (иначе будет "дребезг").
      final isAuthLoading = authAsync.isLoading;
      final isRoleLoading = roleAsync.isLoading;

      // 1) Не авторизован -> только /login
      if (user == null) {
        return isLogin ? null : '/login';
      }

      // 2) Авторизован, но профиль/роль еще грузится
      if (isAuthLoading || isRoleLoading) {
        return null;
      }

      // 3) Авторизован, но роли нет -> /role-select
      if (role == null) {
        return isRoleSelect ? null : '/role-select';
      }

      // 4) Роль есть -> на домашний экран роли, если пользователь на /login или /role-select
      if (isLogin || isRoleSelect) {
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

      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(child: Text(state.error.toString())),
    ),

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // BUYER
      ShellRoute(
        builder: (context, state, child) => BuyerShell(child: child),
        routes: [
          GoRoute(path: '/buyer/home', builder: (context, state) => const CatalogScreen()),
          GoRoute(path: '/buyer/orders', builder: (context, state) => const BuyerOrdersScreen()),
          GoRoute(
            path: '/buyer/product/:id',
            builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
        ],
      ),

      // SELLER
      ShellRoute(
        builder: (context, state, child) => SellerShell(child: child),
        routes: [
          GoRoute(path: '/seller/products', builder: (context, state) => const SellerProductsScreen()),
          GoRoute(path: '/seller/products/add', builder: (context, state) => const SellerAddProductScreen()),
          GoRoute(path: '/seller/orders', builder: (context, state) => const SellerOrdersScreen()),
        ],
      ),

      // WANGHONG
      ShellRoute(
        builder: (context, state, child) => WanghongShell(child: child),
        routes: [
          GoRoute(path: '/wanghong/home', builder: (context, state) => const WanghongHomeScreen()),
        ],
      ),

      // ADMIN
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/moderation', builder: (context, state) => const ModerationScreen()),
          GoRoute(path: '/admin/users', builder: (context, state) => const UsersScreen()),
          GoRoute(path: '/admin/finance', builder: (context, state) => const AdminFinanceScreen()),
        ],
      ),
    ],
  );
});
