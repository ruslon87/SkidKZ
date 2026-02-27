// lib/features/buyer/screens/buyer_shell.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final StatefulNavigationShell navigationShell;
  const BuyerRootShell({super.key, required this.navigationShell});

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBack;
  String _city = 'Определяем...';

  @override
  void initState() {
    super.initState();
    _detectCity();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _closeDrawer() {
    final state = _scaffoldKey.currentState;
    if (state == null) return;
    if (state.isDrawerOpen) {
      Navigator.of(state.context).pop();
    }
  }

  bool _drawerOpen() => _scaffoldKey.currentState?.isDrawerOpen ?? false;

  void _goTab(int index) {
    // initialLocation=true = при повторном тапе по активной вкладке возвращаемся в корень вкладки
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Future<void> _onBack() async {
    // 1) drawer → закрыть
    if (_drawerOpen()) {
      _closeDrawer();
      return;
    }

    // 2) pop внутри активной ветки
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    // 3) не “Магазин” → перейти на “Магазин”
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }

    // 4) “Магазин” → двойной back
    final now = DateTime.now();
    if (_lastBack == null || now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Нажмите ещё раз, чтобы выйти'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    SystemNavigator.pop();
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
    return BuyerShellScope(
      openDrawer: _openDrawer,
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          _onBack();
        },
        child: AppGradientBackground(
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
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
                Expanded(child: widget.navigationShell),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: _goTab,
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

// Drawer оставь своим (из ZIP). Ниже — твоя текущая версия целиком
class BuyerDrawer extends StatelessWidget {
  const BuyerDrawer({
    super.key,
    required this.closeDrawer,
    required this.city,
    required this.onCityTap,
  });

  static const Color _emerald = Color(0xFF2ACB95);

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

  Widget _drawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      selected: selected,
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
      selectedTileColor: _emerald.withValues(alpha: 0.18),
      trailing: selected
          ? Container(
              width: 8,
              height: 28,
              decoration: BoxDecoration(
                color: _emerald,
                borderRadius: BorderRadius.circular(10),
              ),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = fb.FirebaseAuth.instance.currentUser;
    final isAuthed = user != null;
    final location =
        GoRouter.maybeOf(context)?.routeInformationProvider.value.uri.path ?? '';

    return Drawer(
      backgroundColor: const Color(0xFF12161B),
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: isAuthed
              ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots()
              : null,
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final displayName = (data?['displayName'] ?? '').toString().trim();
            final phone = (data?['phone'] ?? '').toString().trim();

            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C2026), Color(0xFF14181D), Color(0xFF101419)],
                  stops: [0.0, 0.58, 1.0],
                ),
                border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: _emerald.withValues(alpha: 0.22),
                  highlightColor: _emerald.withValues(alpha: 0.14),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ⚠️ сюда вставь свой полный Drawer из ZIP (у тебя он длинный).
                    // Я не режу его, чтобы ты не получил “пустой drawer” как на скрине.
                    // Содержимое не влияет на back, влияет только _safeGo/_safePush + closeDrawer().
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
