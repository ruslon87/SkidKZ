import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class BuyerShellScope extends InheritedWidget {
  const BuyerShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static BuyerShellScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BuyerShellScope>();
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant BuyerShellScope oldWidget) =>
      oldWidget.openDrawer != openDrawer;
}

class BuyerRootShell extends StatefulWidget {
  final Widget child;
  const BuyerRootShell({super.key, required this.child});

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  String _city = 'Определяем...';
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _detectCity();
  }

  Future<void> _detectCity() async {
    try {
      if (!mounted) return;

      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _city = 'Геолокация выкл.');
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _city = 'Нет доступа');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city =
            p.locality ??
            p.subAdministrativeArea ??
            p.administrativeArea ??
            'Неизвестно';

        setState(() => _city = city);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _city = 'Ошибка');
    }
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0;
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
    final currentIndex = _locationToIndex(location);

    final rootNav =
        Navigator.of(context, rootNavigator: true);

    // Закрываем drawer/dialog
    if (rootNav.canPop()) {
      rootNav.pop();
      return false;
    }

    // Если не на Магазине → перейти на Магазин
    if (currentIndex != 0) {
      context.go('/buyer/home');
      return false;
    }

    // Двойной Back для выхода
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) >
            const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
                'Нажмите ещё раз, чтобы выйти'),
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
      child: BuyerShellScope(
        openDrawer: () =>
            _scaffoldKey.currentState?.openDrawer(),
        child: Scaffold(
          key: _scaffoldKey,
          drawer: const BuyerDrawer(),
          body: Column(
            children: [
              _BuyerTopBar(
                city: _city,
                onMenu: () =>
                    _scaffoldKey.currentState?.openDrawer(),
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
            unselectedItemColor:
                AppTheme.textDisabled,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.store),
                  label: 'Магазин'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view),
                  label: 'Каталог'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  label: 'Избранное'),
              BottomNavigationBarItem(
                  icon:
                      Icon(Icons.shopping_cart_outlined),
                  label: 'Корзина'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Профиль'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyerTopBar extends StatelessWidget {
  final String city;
  final VoidCallback onMenu;
  final VoidCallback onCityTap;

  const _BuyerTopBar({
    required this.city,
    required this.onMenu,
    required this.onCityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.elevated,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding:
              const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: AppTheme.divider),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onMenu,
                icon: Icon(Icons.menu,
                    color:
                        AppTheme.textPrimary),
              ),
              const SizedBox(width: 6),
              Text(
                'SkidKZ',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCityTap,
                child: Row(
                  children: [
                    Icon(
                        Icons.location_on_outlined,
                        color: AppTheme
                            .textSecondary,
                        size: 18),
                    const SizedBox(width: 6),
                    Text(
                      city,
                      style: TextStyle(
                        color: AppTheme
                            .textSecondary,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class BuyerDrawer extends StatelessWidget {
  const BuyerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: ListView(
          children: const [
            SizedBox(height: 16),
            ListTile(
              title: Text(
                'SkidKZ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
