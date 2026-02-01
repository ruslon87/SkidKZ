import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
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

  int _locationToIndex(String location) {
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
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

  void _toggleCity() {
    setState(() {
      _city = _city == 'Алматы' ? 'Астана' : 'Алматы';
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      drawer: const BuyerDrawer(),

      // ✅ фиксированная шапка везде
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'SkidKZ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          InkWell(
            onTap: _toggleCity,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _city,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ],
      ),

      body: widget.child,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _onTabTap(context, i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Магазин'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Каталог'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Избранное'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined), label: 'Корзина'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}

class BuyerDrawer extends StatelessWidget {
  const BuyerDrawer({super.key});

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _displayName(fb.User u) {
    final dn = (u.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final phone = (u.phoneNumber ?? '').trim();
    if (phone.isNotEmpty) return phone;

    final email = (u.email ?? '').trim();
    if (email.isNotEmpty) return email;

    return 'Пользователь';
  }

  String _subtitle(fb.User u) {
    final email = (u.email ?? '').trim();
    final phone = (u.phoneNumber ?? '').trim();

    if (phone.isNotEmpty && email.isNotEmpty) return '$phone • $email';
    if (phone.isNotEmpty) return phone;
    if (email.isNotEmpty) return email;

    return 'Аккаунт SkidKZ';
  }

  Future<void> _signOutAndClose(BuildContext context) async {
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {
      // молча, это MVP
    }

    if (Navigator.canPop(context)) Navigator.pop(context);
    // после выхода — остаёмся в публичной зоне покупателя
    context.go('/buyer/home');
  }

  void _closeDrawer(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: StreamBuilder<fb.User?>(
        stream: fb.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          final user = snap.data; // null => гость
          final isAuthed = user != null;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // -------------------------
              // HEADER (синий + умная карточка)
              // -------------------------
              Container(
                color: AppTheme.primary,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SkidKZ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: () {
                        _closeDrawer(context);
                        if (isAuthed) {
                          context.go('/buyer/profile');
                        } else {
                          context.go('/login');
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            // аватар
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isAuthed
                                    ? Icons.person
                                    : Icons.person_outline,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // тексты
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAuthed
                                        ? _displayName(user!)
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
                                        ? _subtitle(user!)
                                        : 'Заказы, избранное, бонусы',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Text(
                          isAuthed ? 'Покупатель' : 'Гость',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),

                        if (isAuthed)
                          TextButton(
                            onPressed: () => _signOutAndClose(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Выйти',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // -------------------------
              // АККАУНТ
              // -------------------------
              _sectionTitle('Аккаунт'),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Мои заказы'),
                onTap: () {
                  _closeDrawer(context);
                  if (isAuthed) {
                    // пока можно вести в профиль (когда появится orders screen — поменяем)
                    context.go('/buyer/profile');
                  } else {
                    context.go('/login');
                  }
                },
              ),

              const Divider(height: 1),

              // -------------------------
              // КАБИНЕТЫ
              // -------------------------
              _sectionTitle('Кабинеты'),
              ListTile(
                leading: const Icon(Icons.store_mall_directory_outlined),
                title: const Text('Кабинет магазина'),
                subtitle: const Text('Продажи, товары, заказы'),
                onTap: () {
                  _closeDrawer(context);
                  // умно: всегда доступно нажать — роутер сам отправит на /login если надо
                  context.go('/cabinet');
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Кабинет ванхуна'),
                subtitle: const Text('Заработать на промокодах'),
                onTap: () {
                  _closeDrawer(context);
                  context.go('/cabinet');
                },
              ),

              const Divider(height: 1),

              // -------------------------
              // СЕРВИС
              // -------------------------
              _sectionTitle('Сервис'),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Поддержка'),
                onTap: () => _closeDrawer(context),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('О приложении'),
                onTap: () => _closeDrawer(context),
              ),

              const Divider(height: 1),

              // -------------------------
              // ДЛЯ БИЗНЕСА (ВСЕГДА ВНИЗУ, ВСЕГДА ВИДНО/ДОСТУПНО)
              // -------------------------
              _sectionTitle('Для бизнеса'),
              ListTile(
                leading: const Icon(Icons.add_business_outlined),
                title: const Text('Открыть магазин'),
                subtitle: const Text('Как это работает'),
                onTap: () {
                  _closeDrawer(context);
                  // TODO: context.go('/info/seller');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('Подключиться как ванхун'),
                subtitle: const Text('Условия и старт'),
                onTap: () {
                  _closeDrawer(context);
                  // TODO: context.go('/info/wanghong');
                },
              ),

              const Divider(height: 1),

              // -------------------------
              // НИЗ: версия / политика / соглашение
              // -------------------------
              _sectionTitle('Информация'),
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: const Text('Версия приложения'),
                subtitle: const _AppVersionSubtitle(),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: const Text('Политика конфиденциальности'),
                onTap: () {
                  _closeDrawer(context);
                  // TODO: context.go('/legal/privacy');
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Пользовательское соглашение'),
                onTap: () {
                  _closeDrawer(context);
                  // TODO: context.go('/legal/terms');
                },
              ),

              const SizedBox(height: 12),
            ],
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
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _text = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      setState(() {
        _text = 'неизвестно';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_text);
  }
}
