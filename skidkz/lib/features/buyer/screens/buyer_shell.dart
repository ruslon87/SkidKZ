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

/// Скоуп, чтобы дочерние экраны могли открыть Drawer
class BuyerShellScope extends InheritedWidget {
  const BuyerShellScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static BuyerShellScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BuyerShellScope>();
    assert(scope != null, 'BuyerShellScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant BuyerShellScope oldWidget) {
    return oldWidget.openDrawer != openDrawer;
  }
}

class BuyerRootShell extends StatefulWidget {
  final Widget child;
  const BuyerRootShell({super.key, required this.child});

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _city = 'Алматы';
  bool _cityLoading = false;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _initCity();
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0;
  }

  bool _isHomeLocation(String location) {
    return location == '/' || location.startsWith('/buyer/home');
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

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _initCity() async {
    // 1) попробуем гео
    await _refreshCityFromGeo(quiet: true);

    // 2) если гео не дало результата — попробуем из профиля (если авторизован)
    if (!mounted) return;
    if (_city.trim().isEmpty || _city == 'Алматы') {
      final u = fb.FirebaseAuth.instance.currentUser;
      if (u != null) {
        final profileCity = await _fetchBuyerProfileCity(u.uid);
        if (!mounted) return;
        if (profileCity != null && profileCity.trim().isNotEmpty) {
          setState(() => _city = profileCity.trim());
        }
      }
    }
  }

  Future<String?> _fetchBuyerProfileCity(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data();
      if (data == null) return null;

      final profiles = data['profiles'];
      if (profiles is! Map) return null;

      final buyer = profiles['buyer'];
      if (buyer is! Map) return null;

      final city = buyer['city'];
      if (city is String && city.trim().isNotEmpty) return city.trim();
      return null;
    } catch (_) {
      return null;
    }
  }

  String _normalizeCityName(String? raw) {
    var s = (raw ?? '').trim();
    if (s.isEmpty) return '';

    // Частые варианты из геокодинга
    final low = s.toLowerCase();
    if (low == 'almaty') return 'Алматы';
    if (low == 'astana') return 'Астана';
    if (low == 'nur-sultan' || low == 'nursultan') return 'Астана';

    // Иногда locality пустой, а прилетает adminArea
    // Оставляем как есть, но с первой буквой
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  Future<void> _refreshCityFromGeo({bool quiet = false}) async {
    if (_cityLoading) return;
    setState(() => _cityLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!quiet && mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(content: Text('Включите геолокацию на устройстве')));
        }
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!quiet && mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(content: Text('Нет разрешения на геолокацию')));
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 8),
      );

      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isEmpty) return;

      final p = marks.first;

      // locality — чаще всего город. Если пусто — пробуем subAdministrativeArea/adminArea
      final rawCity = p.locality?.trim().isNotEmpty == true
          ? p.locality
          : (p.subAdministrativeArea?.trim().isNotEmpty == true
              ? p.subAdministrativeArea
              : p.administrativeArea);

      final normalized = _normalizeCityName(rawCity);
      if (normalized.isNotEmpty && mounted) {
        setState(() => _city = normalized);
      }
    } catch (_) {
      // молча (гео может падать на части устройств/эмуляторов)
    } finally {
      if (mounted) setState(() => _cityLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    final location = GoRouterState.of(context).uri.toString();
    final router = GoRouter.of(context);

    // закрыть overlay
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) {
      rootNav.pop();
      return false;
    }

    if (router.canPop()) {
      router.pop();
      return false;
    }

    if (!_isHomeLocation(location)) {
      context.go('/buyer/home');
      return false;
    }

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
      child: BuyerShellScope(
        openDrawer: _openDrawer,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: BuyerDrawer(
            city: _city,
            cityLoading: _cityLoading,
            onRefreshCity: () => _refreshCityFromGeo(quiet: false),
          ),

          // единый top bar для всех вкладок
          body: Column(
            children: [
              _BuyerTopBar(
                onMenu: _openDrawer,
                city: _city,
                cityLoading: _cityLoading,
                onCityTap: () => _refreshCityFromGeo(quiet: false),
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
    required this.cityLoading,
    required this.onCityTap,
  });

  final VoidCallback onMenu;
  final String city;
  final bool cityLoading;
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onCityTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        cityLoading ? 'Определяем…' : city,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
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
    required this.city,
    required this.cityLoading,
    required this.onRefreshCity,
  });

  final String city;
  final bool cityLoading;
  final VoidCallback onRefreshCity;

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: TextStyle(
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
    // “белая” подсветка как в bottom nav — через Theme (без ListTileThemeData.splashColor)
    final splash = Colors.white.withOpacity(0.08);
    final highlight = Colors.white.withOpacity(0.05);

    return Drawer(
      backgroundColor: AppTheme.background,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: splash,
          highlightColor: highlight,
          dividerColor: AppTheme.divider,
        ),
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: StreamBuilder<fb.User?>(
                  stream: fb.FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snap) {
                    final user = snap.data;
                    final isAuthed = user != null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // HEADER
                        Container(
                          color: AppTheme.elevated,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SkidKZ',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),

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
                                        decoration: BoxDecoration(
                                          color: AppTheme.elevated,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          isAuthed ? Icons.person : Icons.person_outline,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (!isAuthed)
                                              Text(
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
                                                    style: TextStyle(
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
                                              style: TextStyle(
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
                                      Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ✅ Важно: город в Drawer показываем ТОЛЬКО гостю (чтобы не было дубля)
                              Row(
                                children: [
                                  if (!isAuthed)
                                    Text(
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
                                      builder: (context, roleSnap) {
                                        final role = _roleLabelFromActiveRole(roleSnap.data);
                                        return Text(
                                          role,
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        );
                                      },
                                    ),
                                  const Spacer(),
                                  if (!isAuthed)
                                    InkWell(
                                      onTap: onRefreshCity,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        child: Row(
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                color: AppTheme.textSecondary, size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              cityLoading ? 'Определяем…' : city,
                                              style: TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (isAuthed) ...[
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _signOutAndClose(context),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Выйти',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        _sectionTitle('Аккаунт'),
                        ListTile(
                          leading: Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary),
                          title: Text('Мои заказы', style: TextStyle(color: AppTheme.textPrimary)),
                          onTap: () {
                            _closeDrawer(context);
                            if (isAuthed) {
                              context.go('/buyer/profile');
                            } else {
                              context.push('/login');
                            }
                          },
                        ),
                        Divider(height: 1, color: AppTheme.divider),

                        _sectionTitle('Кабинеты'),
                        ListTile(
                          leading:
                              Icon(Icons.store_mall_directory_outlined, color: AppTheme.textSecondary),
                          title: Text('Кабинет магазина', style: TextStyle(color: AppTheme.textPrimary)),
                          subtitle:
                              Text('Продажи, товары, заказы', style: TextStyle(color: AppTheme.textSecondary)),
                          onTap: () {
                            _closeDrawer(context);
                            context.go('/cabinet');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.campaign_outlined, color: AppTheme.textSecondary),
                          title: Text('Кабинет ванхуна', style: TextStyle(color: AppTheme.textPrimary)),
                          subtitle: Text('Заработать на промокодах',
                              style: TextStyle(color: AppTheme.textSecondary)),
                          onTap: () {
                            _closeDrawer(context);
                            context.go('/cabinet');
                          },
                        ),
                        Divider(height: 1, color: AppTheme.divider),

                        _sectionTitle('Для бизнеса'),
                        ListTile(
                          leading: Icon(Icons.add_business_outlined, color: AppTheme.textSecondary),
                          title: Text('Открыть магазин', style: TextStyle(color: AppTheme.textPrimary)),
                          subtitle:
                              Text('Как это работает', style: TextStyle(color: AppTheme.textSecondary)),
                          onTap: () => context.push('/info/seller'),
                        ),
                        ListTile(
                          leading: Icon(Icons.person_add_alt_1_outlined, color: AppTheme.textSecondary),
                          title:
                              Text('Подключиться как ванхун', style: TextStyle(color: AppTheme.textPrimary)),
                          subtitle: Text('Условия и старт', style: TextStyle(color: AppTheme.textSecondary)),
                          onTap: () => context.push('/info/wanghong'),
                        ),
                        Divider(height: 1, color: AppTheme.divider),

                        _sectionTitle('Сервис'),
                        ListTile(
                          leading: Icon(Icons.support_agent_outlined, color: AppTheme.textSecondary),
                          title: Text('Поддержка', style: TextStyle(color: AppTheme.textPrimary)),
                          onTap: () => _closeDrawer(context),
                        ),
                        Divider(height: 1, color: AppTheme.divider),

                        _sectionTitle('Информация'),
                        ListTile(
                          leading: Icon(Icons.verified_outlined, color: AppTheme.textSecondary),
                          title: Text('Версия приложения', style: TextStyle(color: AppTheme.textPrimary)),
                          subtitle: const _AppVersionSubtitle(),
                          onTap: () {},
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ✅ “как на референсе”: мягкая дымка справа (внутри drawer)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.04),
                        Colors.black.withOpacity(0.18),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _text = '${info.version} (${info.buildNumber})');
    } catch (_) {
      setState(() => _text = '-');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_text, style: TextStyle(color: AppTheme.textSecondary));
  }
}
