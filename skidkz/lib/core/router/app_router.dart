import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/role-select',
    refreshListenable: ValueNotifier(authState), 
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoggingIn = state.uri.toString() == '/role-select' || state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/role-select';
      
      if (isLoggedIn && isLoggingIn) {
        switch (authState.role) {
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
    routes: [
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // BUYER
      ShellRoute(
        builder: (context, state, child) => BuyerShell(child: child),
        routes: [
          GoRoute(path: '/buyer/home', builder: (context, state) => const CatalogScreen()),
          GoRoute(path: '/buyer/orders', builder: (context, state) => const BuyerOrdersScreen()),
          GoRoute(path: '/buyer/product/:id', builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
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
        ],
      ),
    ],
  );
});
