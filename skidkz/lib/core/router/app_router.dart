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

/// --- Firebase singletons ---
final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Auth stream
final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// ActiveRole из users/{uid}.activeRole (buyer/wanghong/seller/admin) или null
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

/// Router refresh helper
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _sub1 = ref.listen<AsyncValue<fb.User?>>(authStateChangesProvider, (_, __) {
      notifyListeners();
    });
    _sub2 = ref.listen<AsyncValue<UserRole?>>(activeRoleProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
  late final ProviderSubscription<AsyncValue<fb.User?>> _sub1;
  late final ProviderSubscription<AsyncValue<UserRole?>> _sub2;

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
    // A) Витрина = стартовая
    initialLocation: '/buyer/home',
    refreshListenable: refresh,

    redirect: (context, state) {
      final location = state.uri.toString();

      // Разрешаем покупательские экраны без авторизации
      final isPublicBuyer =
          location.startsWith('/buyer') || location == '/' || location.isEmpty;

      final authAsync = ref.read(authStateChangesProvider);
      final fbUser = authAsync.asData?.value; // <-- вместо valueOrNull

      final roleAsync = ref.read(activeRoleProvider);
      final activeRole = roleAsync.asData?.value; // <-- вместо valueOrNull

      final isLoading = authAsync.isLoading || roleAsync.isLoading;

      final isLogin = location == '/login';
      final isRoleSelect = location == '/role-select';

      // Пока грузится — не дёргаем редиректы, иначе будет "дребезг"
      if (isLoading) return null;

      // 1) Если пользователь НЕ залогинен:
      // - покупательские страницы разрешены
      // - кабинетные страницы запрещены -> /login
      if (fbUser == null) {
        if (isPublicBuyer) return null;
        if (_isCabinetArea(location) || !isPublicBuyer) {
          return isLogin ? null : '/login';
        }
        return null;
      }

      // 2) Пользователь залогинен:
      // /login больше не нужен
      if (isLogin) {
        // после логина ведём в /cabinet (там решится дальше)
        return '/cabinet';
      }

      // 3) Кабинетный роутер:
      // Если role ещё не выбрали -> /role-select
      if (_isCabinetArea(location)) {
        if (activeRole == null) {
          return isRoleSelect ? null : '/role-select';
        }
        // если пользователь на /role-select, но роль уже есть — ведём в дом роли
        if (isRoleSelect) {
          return _homeForRole(activeRole);
        }
        // /cabinet -> дом роли
        if (location == '/cabinet') {
          return _homeForRole(activeRole);
        }
      }

      // 4) Если роль есть, но юзер случайно пошёл на чужой кабинет — оставим как есть (MVP),
      // позже можно добавить проверку доступа по roles map.
      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(child: Text(state.error.toString())),
    ),

    routes: [
      // LOGIN + ROLE SELECT (кабинетные шаги)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Технический “вход” в кабинет: всегда ведём сюда, а redirect решит куда дальше
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

      // SELLER (только после логина)
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
