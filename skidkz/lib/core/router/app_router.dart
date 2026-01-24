// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/data/models/user_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';

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

/// Обновляет GoRouter при изменениях Firebase auth и профиля/роли.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _sub1 = ref.listen(firebaseUserProvider, (_, __) => notifyListeners());
    _sub2 = ref.listen(currentUserProfileProvider, (_, __) => notifyListeners());
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

      final authAsync = ref.read(firebaseUserProvider);
      final fbUser = authAsync.asData?.value;

      final profileAsync = ref.read(currentUserProfileProvider);
      final profile = profileAsync.asData?.value;

      final isLogin = location == '/login';
      final isRoleSelect = location == '/role-select';

      // Пока грузится auth / профиль — не делаем резких редиректов
      if (authAsync.isLoading || profileAsync.isLoading) return null;

      // 1) Не авторизован -> только /login
      if (fbUser == null) {
        return isLogin ? null : '/login';
      }

      // 2) Авторизован, но роль не задана -> /role-select
      final role = profile?.role;
      if (role == null) {
        return isRoleSelect ? null : '/role-select';
      }

      // 3) Роль задана -> если на /login или /role-select, уводим в нужный раздел
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
