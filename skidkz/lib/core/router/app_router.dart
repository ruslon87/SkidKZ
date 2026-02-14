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
import 'package:skidkz/features/buyer/screens/buyer_orders_screen.dart';

import 'package:skidkz/features/seller/screens/seller_shell.dart';
import 'package:skidkz/features/seller/screens/seller_products_screen.dart';
import 'package:skidkz/features/seller/screens/seller_add_product_screen.dart';
import 'package:skidkz/features/seller/screens/seller_orders_screen.dart';

import 'package:skidkz/features/wanghong/screens/wanghong_shell.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_home_screen.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_deals_screen.dart';
import 'package:skidkz/features/wanghong/screens/wanghong_wallet_screen.dart';

import 'package:skidkz/features/admin/screens/admin_shell.dart';
import 'package:skidkz/features/admin/screens/moderation_screen.dart';
import 'package:skidkz/features/admin/screens/users_screen.dart';
import 'package:skidkz/features/admin/screens/admin_finance_screen.dart';

import 'package:skidkz/features/info/screens/seller_info_screen.dart';
import 'package:skidkz/features/info/screens/wanghong_info_screen.dart';

import 'package:skidkz/features/onboarding/screens/buyer_onboarding_screen.dart';

final firebaseAuthProvider =
    Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserDocProvider = FutureProvider<UserModel?>((ref) async {
  final fbUser = await ref.watch(authStateChangesProvider.future);
  if (fbUser == null) return null;

  final db = ref.watch(firestoreProvider);
  final refDoc = db.collection('users').doc(fbUser.uid);
  final snap = await refDoc.get();

  if (!snap.exists) {
    await refDoc.set({
      'uid': fbUser.uid,
      'phone': fbUser.phoneNumber ?? '',
      'roles': ['buyer'],
      'activeRole': 'buyer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'profiles': {
        'buyer': {'completed': false, 'city': 'Алматы'},
        'seller': {'completed': false},
        'wanghong': {'completed': false},
      },
    });

    final created = await refDoc.get();
    return UserModel.fromFirestore(created.id, created.data() ?? {});
  }

  return UserModel.fromFirestore(snap.id, snap.data() ?? {});
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _subAuth = ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _subUser = ref.listen(currentUserDocProvider, (_, __) => notifyListeners());
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

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/buyer/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.uri.toString();

      final authAsync = ref.read(authStateChangesProvider);
      final userAsync = ref.read(currentUserDocProvider);

      final fbUser = authAsync.asData?.value;
      final user = userAsync.asData?.value;

      if (authAsync.isLoading || userAsync.isLoading) return null;

      final isLogin = location.startsWith('/login');

      // Публичные разделы
      if (location.startsWith('/buyer') ||
          location.startsWith('/info') ||
          location == '/') {
        return null;
      }

      if (fbUser == null) {
        return isLogin ? null : '/login';
      }

      if (location == '/cabinet' && user != null) {
        switch (user.activeRole) {
          case UserRole.buyer:
            return '/buyer/home';
          case UserRole.seller:
            return '/seller/products';
          case UserRole.wanghong:
            return '/wanghong/home';
          case UserRole.admin:
            return '/admin/moderation';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          nextPath: state.uri.queryParameters['next'],
        ),
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

      // Buyer Shell Routes
      ShellRoute(
        builder: (context, state, child) => BuyerRootShell(child: child),
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
          GoRoute(
            path: '/buyer/orders',
            builder: (context, state) => const BuyerOrdersScreen(),
          ),
        ],
      ),

      // Seller Shell Routes
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

      // Wanghong Shell Routes
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

      // Admin Shell Routes
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
