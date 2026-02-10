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

import 'package:skidkz/features/info/screens/seller_info_screen.dart';
import 'package:skidkz/features/info/screens/wanghong_info_screen.dart';

import 'package:skidkz/features/onboarding/screens/buyer_onboarding_screen.dart';

/// --------------------
/// Firebase singletons
/// --------------------
final firebaseAuthProvider =
    Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// --------------------
/// Auth stream provider
/// --------------------
final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// --------------------
/// Ensure/Migrate user doc provider
/// - creates users/{uid} if missing
/// - migrates legacy role/activeRole -> roles[]
/// - returns UserModel
/// --------------------
final currentUserDocProvider = FutureProvider<UserModel?>((ref) async {
  final fbUser = await ref.watch(authStateChangesProvider.future);
  if (fbUser == null) return null;

  final db = ref.watch(firestoreProvider);
  final refDoc = db.collection('users').doc(fbUser.uid);

  final snap = await refDoc.get();

  // Create if missing
  if (!snap.exists) {
    final phone = (fbUser.phoneNumber ?? '').trim();

    await refDoc.set({
      'uid': fbUser.uid,
      'phone': phone,
      'roles': ['buyer'],
      'activeRole': 'buyer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'profiles': {
        'buyer': {
          'completed': false,
          'city': 'Алматы',
        },
        'seller': {'completed': false},
        'wanghong': {'completed': false},
      },
    });

    final created = await refDoc.get();
    return UserModel.fromFirestore(created.id, created.data() ?? {});
  }

  final data = snap.data() ?? {};

  // Migrate legacy fields to roles[]
  final hasRoles = data['roles'] is List;
  final legacyRole = data['role'];
  final legacyActive = data['activeRole'];

  if (!hasRoles && legacyRole is String && legacyRole.trim().isNotEmpty) {
    final active = (legacyActive is String && legacyActive.trim().isNotEmpty)
        ? legacyActive.trim()
        : legacyRole.trim();

    await refDoc.set({
      'roles': [legacyRole.trim()],
      'activeRole': active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final migrated = await refDoc.get();
    return UserModel.fromFirestore(migrated.id, migrated.data() ?? {});
  }

  return UserModel.fromFirestore(snap.id, data);
});

/// --------------------
/// Router refresh helper
/// --------------------
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    _subAuth = ref.listen<AsyncValue<fb.User?>>(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
    );

    _subUser = ref.listen<AsyncValue<UserModel?>>(
      currentUserDocProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref ref;
  late final ProviderSubscription<AsyncValue<fb.User?>> _subAuth;
  late final ProviderSubscription<AsyncValue<UserModel?>> _subUser;

  @override
  void dispose() {
    _subAuth.close();
    _subUser.close();
    super.dispose();
  }
}

/// --------------------
/// Helpers
/// --------------------
bool _isPublicArea(String location) {
  return location == '/' ||
      location.startsWith('/buyer') ||
      location.startsWith('/info');
}

bool _isCabinetArea(String location) {
  return location == '/cabinet' ||
      location == '/login' ||
      location == '/role-select' ||
      location.startsWith('/seller') ||
      location.startsWith('/wanghong') ||
      location.startsWith('/admin') ||
      location.startsWith('/onboarding');
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

bool _hasRole(UserModel u, UserRole r) => u.roles.contains(r);

/// --------------------
/// Router
/// --------------------
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

      final isLoading = authAsync.isLoading || userAsync.isLoading;

      final isLogin = location.startsWith('/login');
      final isBuyerOnboarding = location.startsWith('/onboarding/buyer');

      if (isLoading) return null;

      // 1) Public buyer + info always ok
      if (_isPublicArea(location)) {
        return null;
      }

      // 2) Cabinet/auth areas
      if (_isCabinetArea(location)) {
        // Not authed
        if (fbUser == null) {
          return isLogin ? null : '/login';
        }

        // Authed but user doc not ready (rare race)
        if (user == null) {
          return null;
        }

        // If activeRole == buyer and buyer profile not completed -> force onboarding
        final buyerNeed = user.activeRole == UserRole.buyer &&
            user.buyerProfile.completed != true;

        if (buyerNeed && !isBuyerOnboarding) {
          final next = Uri.encodeComponent('/buyer/home');
          return '/onboarding/buyer?next=$next';
        }

        // login not needed when authed
        if (isLogin) {
          return '/cabinet';
        }

        // /cabinet -> go to home by activeRole
        if (location == '/cabinet') {
          return _homeForRole(user.activeRole);
        }

        // Block foreign zones by permissions (roles[])
        if (location.startsWith('/seller') && !_hasRole(user, UserRole.seller)) {
          return _homeForRole(user.activeRole);
        }
        if (location.startsWith('/wanghong') &&
            !_hasRole(user, UserRole.wanghong)) {
          return _homeForRole(user.activeRole);
        }
        if (location.startsWith('/admin') && !_hasRole(user, UserRole.admin)) {
          return _homeForRole(user.activeRole);
        }

        return null;
      }

      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(child: Text(state.error.toString())),
    ),

    routes: [
      /// -------------------------
      /// PUBLIC INFO
      /// -------------------------
      GoRoute(
        path: '/info/seller',
        builder: (context, state) => const SellerInfoScreen(),
      ),
      GoRoute(
        path: '/info/wanghong',
        builder: (context, state) => const WanghongInfoScreen(),
      ),

      /// -------------------------
      /// ONBOARDING (AUTH REQUIRED)
      /// -------------------------
      GoRoute(
        path: '/onboarding/buyer',
        builder: (context, state) => const BuyerOnboardingScreen(),
      ),

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
        builder: (context, state) => const _CabinetResolverScreen(),
      ),

      /// -------------------------
      /// BUYER (PUBLIC) SHELL
      /// -------------------------
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

/// --------------------
/// Кабинет-резолвер (UX для пункта A)
/// --------------------
class _CabinetResolverScreen extends ConsumerWidget {
  const _CabinetResolverScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final userAsync = ref.watch(currentUserDocProvider);

    final fbUser = authAsync.asData?.value;

    String text = 'Подготавливаем вход…';

    if (authAsync.isLoading) {
      text = 'Проверяем сессию…';
    } else if (fbUser == null) {
      text = 'Требуется вход…';
    } else if (userAsync.isLoading) {
      text = 'Создаём профиль…';
    } else if (userAsync.hasError) {
      text = 'Ошибка профиля: ${userAsync.error}';
    } else {
      text = 'Готово…';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
