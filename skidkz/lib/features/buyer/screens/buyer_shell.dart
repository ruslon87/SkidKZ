// lib/features/buyer/screens/buyer_shell.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/core/widgets/app_gradient_background.dart';

/// Скоуп, чтобы дочерние экраны могли открыть drawer
class BuyerShellScope extends InheritedWidget {
  final VoidCallback openDrawer;
  const BuyerShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static BuyerShellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BuyerShellScope>()!;

  @override
  bool updateShouldNotify(covariant BuyerShellScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}

class BuyerRootShell extends StatefulWidget {
  final Widget child;
  const BuyerRootShell({super.key, required this.child});

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _city = 'Определяем...';

  @override
  void initState() {
    super.initState();
    _detectCity(); // при запуске
  }

  String _safeLocation(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return '/buyer/home';
    return router.routeInformationProvider.value.uri.path;
  }

  int _locationToIndex(String path) {
    if (path.startsWith('/buyer/catalog')) return 1;
    if (path.startsWith('/buyer/favorites')) return 2;
    if (path.startsWith('/buyer/cart')) return 3;
    if (path.startsWith('/buyer/profile')) return 4;
    return 0; // home
  }

  void _goTab(BuildContext context, int index) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    
    switch (index) {
      case 0:
        router.go('/buyer/home');
        break;
      case 1:
        router.go('/buyer/catalog');
        break;
      case 2:
        router.go('/buyer/favorites');
        break;
      case 3:
        router.go('/buyer/cart');
        break;
      case 4:
        router.go('/buyer/profile');
        break;
    }
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _closeDrawer() {
    final state = _scaffoldKey.currentState;
    if (state == null) return;
    if (state.isDrawerOpen) {
      Navigator.of(state.context).pop();
    }
  }

  Future<void> _detectCity() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _city = 'Геолокация выкл.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _city = 'Геолокация откл.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _city = 'Геолокация запрещена');
        return;
      }

      if (!mounted) return;
      setState(() => _city = 'Определяем...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = 'Неизвестно';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = (p.locality ?? '').trim();
        if (city.isEmpty) city = (p.subAdministrativeArea ?? '').trim();
        if (city.isEmpty) city = (p.administrativeArea ?? '').trim();
        if (city.isEmpty) city = 'Неизвестно';
      }

      if (!mounted) return;
      setState(() => _city = city);
    } catch (_) {
      if (!mounted) return;
      setState(() => _city = 'Ошибка');
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _safeLocation(context);
    final currentIndex = _locationToIndex(path);

    return BuyerShellScope(
      openDrawer: _openDrawer,
      child: AppGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          key: _scaffoldKey,
          drawer: BuyerDrawer(
            closeDrawer: _closeDrawer,
            city: _city,
            onCityTap: _detectCity,
          ),
          body: Column(
            children: [
              _BuyerTopBar(
                onMenu: _openDrawer,
                city: _city,
                onCityTap: _detectCity,
              ),
              Expanded(child: widget.child),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (i) => _goTab(context, i),
            type: BottomNavigationBarType.fixed,
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

class _BuyerTopBar extends StatelessWidget {
  const _BuyerTopBar({
    required this.onMenu,
    required this.city,
    required this.onCityTap,
  });

  final VoidCallback onMenu;
  final String city;
  final VoidCallback onCityTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.elevated,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onMenu,
                icon: Icon(Icons.menu, color: AppTheme.textPrimary),
                splashRadius: 22,
              ),
              const SizedBox(width: 6),
              Text(
                'SkidKZ',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onCityTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        city,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
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
    required this.closeDrawer,
    required this.city,
    required this.onCityTap,
  });

  final VoidCallback closeDrawer;
  final String city;
  final VoidCallback onCityTap;

  void _safeGo(BuildContext context, String path) {
    closeDrawer();
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(path);
    }
  }

  void _safePush(BuildContext context, String path) {
    closeDrawer();
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = fb.FirebaseAuth.instance.currentUser;
    final isAuthed = user != null;

    return Drawer(
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: isAuthed
              ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots()
              : null,
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final displayName = (data?['displayName'] ?? '').toString().trim();
            final phone = (data?['phone'] ?? '').toString().trim();

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF202625),
                        Color(0xFF1A1F1E),
                        Color(0xFF121817),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: const Icon(Icons.person_outline, color: Colors.white70),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (isAuthed) {
                                  _safeGo(context, '/buyer/profile');
                                } else {
                                  _safePush(context, '/login?next=%2Fbuyer%2Fprofile');
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAuthed
                                          ? (displayName.isNotEmpty ? displayName : 'Профиль')
                                          : 'Войти / Регистрация',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isAuthed
                                          ? (phone.isNotEmpty ? phone : 'Заказы, избранное, бонусы')
                                          : 'Заказы, избранное, бонусы',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white70),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('Гость', style: TextStyle(color: Colors.white60)),
                          const Spacer(),
                          InkWell(
                            onTap: onCityTap,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: Colors.white70, size: 18),
                                  const SizedBox(width: 6),
                                  Text(city, style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Аккаунт', style: TextStyle(color: AppTheme.textDisabled)),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Мои заказы'),
                  onTap: () => _safeGo(context, '/buyer/orders'),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Кабинеты', style: TextStyle(color: AppTheme.textDisabled)),
                ),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Кабинет магазина'),
                  subtitle: const Text('Продажи, товары, заказы'),
                  onTap: () => _safeGo(context, '/info/seller'),
                ),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: const Text('Кабинет ванхуна'),
                  subtitle: const Text('Заработать на промокодах'),
                  onTap: () => _safeGo(context, '/info/wanghong'),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Сервис', style: TextStyle(color: AppTheme.textDisabled)),
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('Поддержка'),
                  onTap: () {},
                ),
                const Divider(height: 1),

                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) {
                    final version = snap.data?.version ?? '';
                    final buildNumber = snap.data?.buildNumber ?? '';
                    final v = (version.isEmpty) ? '' : 'v$version ($buildNumber)';

                    return ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Версия приложения'),
                      subtitle: Text(v.isEmpty ? '...' : v),
                      onTap: () {},
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
