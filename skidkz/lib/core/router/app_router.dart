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

import 'package:skidkz/core/widgets/disabled_feature_screen.dart';

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
        'buyer': {'completed': false},
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

      // Гость: разрешаем buyer-витрину и login/role-select
      final isGuestAllowed =
          location.startsWith('/buyer') ||
          location.startsWith('/login') ||
          location.startsWith('/role-select');

      if (fbUser == null) {
        return isGuestAllowed ? null : '/login';
      }

      // Авторизован: если вдруг попал на /login, отправляем на buyer/home
      if (location.startsWith('/login')) {
        return '/buyer/home';
      }

      // Роли пока заглушены: любые seller/wanghong/admin пути гоним на заглушку (или на buyer/home)
      if (location.startsWith('/seller') ||
          location.startsWith('/wanghong') ||
          location.startsWith('/admin')) {
        // Можно и на buyer/home, но заглушка нагляднее
        return null;
      }

      // Кабинет пока не используем — на buyer/home
      if (location == '/cabinet' && user != null) {
        return '/buyer/home';
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

      // Buyer Shell Routes (единственный рабочий shell сейчас)
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

      // Заглушки ролей (пути оставляем, чтобы ничего не падало если вдруг кто-то пойдёт туда)
      GoRoute(
        path: '/seller',
        builder: (context, state) =>
            const DisabledFeatureScreen(title: 'Кабинет магазина'),
      ),
      GoRoute(
        path: '/seller/:rest(.*)',
        builder: (context, state) =>
            const DisabledFeatureScreen(title: 'Кабинет магазина'),
      ),
      GoRoute(
        path: '/wanghong',
        builder: (context, state) =>
            const DisabledFeatureScreen(title: 'Кабинет ванхуна'),
      ),
      GoRoute(
        path: '/wanghong/:rest(.*)',
        builder: (context, state) =>
            const DisabledFeatureScreen(title: 'Кабинет ванхуна'),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const DisabledFeatureScreen(title: 'Админка'),
      ),
      GoRoute(
        path: '/admin/:rest(.*)',
        builder: (context, state) =>
            const DisabledFeatureScreen(title: 'Админка'),
      ),
    ],
  );
});
