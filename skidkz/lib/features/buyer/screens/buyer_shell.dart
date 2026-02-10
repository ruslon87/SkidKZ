// lib/features/buyer/screens/buyer_shell.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class BuyerRootShell extends StatefulWidget {
  final Widget child;
  const BuyerRootShell({super.key, required this.child});

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _city = 'Алматы';
  DateTime? _lastBackPress;

  int _locationToIndex(String location) {
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0; // home
  }

  bool _isHomeLocation(String location) {
    return location == '/' || location.startsWith('/buyer/home');
  }

  void _toggleCity() {
    setState(() {
      _city = _city == 'Алматы' ? 'Астана' : 'Алматы';
    });
  }

  void _goTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/buyer/home');
        break;
      case 1:
        context.go('/buyer/catalog');
        break;
      case 2:
        context.go('/buyer/favorites');
        break;
      case 3:
        context.go('/buyer/cart');
        break;
      case 4:
        context.go('/buyer/profile');
        break;
    }
  }

  Future<bool> _onWillPop() async {
    final location = GoRouterState.of(context).uri.toString();
    final router = GoRouter.of(context);

    // 0) Закрыть любой overlay (drawer/dialog/bottomsheet) — первым делом
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) {
      rootNav.pop();
      return false;
    }

    // 1) Если есть что pop в роутере — pop
    if (router.canPop()) {
      router.pop();
      return false;
    }

    // 2) Если не home — на home
    if (!_isHomeLocation(location)) {
      context.go('/buyer/home');
      return false;
    }

    // 3) На home — двойной Back = выход
    final now = DateTime.now();
    final last = _lastBackPress;

    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Нажмите ещё раз, чтобы выйти'),
            duration: Duration(seconds: 2),
          ),
        );
      return false;
    }

    SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTheme.background,
        drawer: BuyerDrawer(
          city: _city,
          onToggleCity: _toggleCity,
        ),
        body: widget.child,

        // Divider сверху + Bottom bar как у Freedom (спокойно, читаемо)
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTheme.elevated,
            border: Border(
              top: BorderSide(color: AppTheme.divider, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (i) => _goTab(context, i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.elevated,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textDisabled,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Магазин'),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Каталог'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Избранное'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Корзина'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профиль'),
            ],
          ),
        ),
      ),
    );
  }
}

class BuyerDrawer extends StatelessWidget {
  const BuyerDrawer({
    super.key,
    required this.city,
    required this.onToggleCity,
  });

  final String city;
  final VoidCallback onToggleCity;

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textDisabled,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _closeDrawer(BuildContext context) {
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) rootNav.pop();
  }

  String _subtitle(fb.User u) {
    final email = (u.email ?? '').trim();
    final phone = (u.phoneNumber ?? '').trim();
    if (phone.isNotEmpty && email.isNotEmpty) return '$phone • $email';
    if (phone.isNotEmpty) return phone;
    if (email.isNotEmpty) return email;
    return 'Аккаунт SkidKZ';
  }

  String _roleLabelFromActiveRole(String? activeRole) {
    switch ((activeRole ?? 'buyer').toLowerCase()) {
      case 'admin':
        return 'Админ';
      case 'seller':
        return 'Продавец';
      case 'wanghong':
        return 'Ванхун';
      default:
        return 'Покупатель';
    }
  }

  Stream<String?> _activeRoleStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['activeRole'] as String?);
  }

  Stream<String?> _buyerFullNameStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final profiles = data['profiles'];
      if (profiles is! Map) return null;
      final buyer = profiles['buyer'];
      if (buyer is! Map) return null;
      final fullName = buyer['fullName'];
      if (fullName is String && fullName.trim().isNotEmpty) return fullName.trim();
      return null;
    });
  }

  Future<void> _signOutAndClose(BuildContext context) async {
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}
    _closeDrawer(context);
    context.go('/buyer/home');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: StreamBuilder<fb.User?>(
        stream: fb.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          final user = snap.data;
          final isAuthed = user != null;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER (Graphite)
                  Container(
                    color: AppTheme.elevated,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SkidKZ',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // карточка аккаунта
                        InkWell(
                          onTap: () {
                            _closeDrawer(context);
                            if (isAuthed) {
                              context.go('/buyer/profile');
                            } else {
                              context.push('/login');
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.background,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isAuthed ? Icons.person : Icons.person_outline,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isAuthed)
                                        const Text(
                                          'Войти / Регистрация',
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        )
                                      else
                                        StreamBuilder<String?>(
                                          stream: _buyerFullNameStream(user!.uid),
                                          builder: (context, nameSnap) {
                                            final name = nameSnap.data;
                                            final fallback =
                                                (user.phoneNumber ?? '').trim().isNotEmpty
                                                    ? (user.phoneNumber ?? '').trim()
                                                    : 'Пользователь';
                                            return Text(
                                              name ?? fallback,
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isAuthed ? _subtitle(user!) : 'Заказы, избранное, бонусы',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // нижняя строка: роль + город + выйти
                        Row(
                          children: [
                            if (!isAuthed)
                              const Text(
                                'Гость',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              StreamBuilder<String?>(
                                stream: _activeRoleStream(user!.uid),
                                builder
