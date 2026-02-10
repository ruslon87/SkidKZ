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
  String _city = 'Алматы';
  DateTime? _lastBackPress;

  int _locationToIndex(String location) {
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0;
  }

  bool _isHome(String location) =>
      location == '/' || location.startsWith('/buyer/home');

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

    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) {
      rootNav.pop();
      return false;
    }

    if (router.canPop()) {
      router.pop();
      return false;
    }

    if (!_isHome(location)) {
      context.go('/buyer/home');
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
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
        drawer: BuyerDrawer(city: _city, onToggleCity: _toggleCity),
        body: widget.child,

        /// ---------- BOTTOM NAV (FREEDOM STYLE) ----------
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppTheme.elevated,
            border: Border(
              top: BorderSide(color: AppTheme.divider, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: List.generate(5, (index) {
              final isActive = index == currentIndex;
              final iconData = [
                Icons.store,
                Icons.grid_view,
                Icons.favorite_border,
                Icons.shopping_cart_outlined,
                Icons.person_outline,
              ][index];
              final label = [
                'Магазин',
                'Каталог',
                'Избранное',
                'Корзина',
                'Профиль',
              ][index];

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _goTab(context, index),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData,
                          size: 22,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.textDisabled,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w800 : FontWeight.w600,
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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

  String _subtitle(fb.User u) {
    final phone = (u.phoneNumber ?? '').trim();
    return phone.isNotEmpty ? phone : 'Аккаунт SkidKZ';
  }

  Stream<String?> _buyerName(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      final p = doc.data()?['profiles']?['buyer'];
      return p is Map && p['fullName'] is String ? p['fullName'] : null;
    });
  }

  void _close(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: StreamBuilder<fb.User?>(
        stream: fb.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          final user = snap.data;
          final isAuthed = user != null;

          return SafeArea(
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.elevated,
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
                      InkWell(
                        onTap: () {
                          _close(context);
                          isAuthed
                              ? context.go('/buyer/profile')
                              : context.push('/login');
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.person,
                                color: AppTheme.textPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: isAuthed
                                  ? StreamBuilder<String?>(
                                      stream: _buyerName(user!.uid),
                                      builder: (_, s) => Text(
                                        s.data ?? _subtitle(user),
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Войти / Регистрация',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: onToggleCity,
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              city,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AppVersionSubtitle extends StatefulWidget {
  const _AppVersionSubtitle();

  @override
  State<_AppVersionSubtitle> createState() => _AppVersionSubtitleState();
}

class _AppVersionSubtitleState extends State<_AppVersionSubtitle> {
  String _text = '...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _text = '${info.version} (${info.buildNumber})');
  }

  @override
  Widget build(BuildContext context) => Text(_text);
}
