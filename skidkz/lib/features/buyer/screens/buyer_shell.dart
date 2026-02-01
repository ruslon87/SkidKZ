import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class BuyerShell extends StatefulWidget {
  final Widget child;
  const BuyerShell({super.key, required this.child});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
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
    // TODO: потом сделаем нормальный выбор города
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

      // ✅ ФИКСИРОВАННАЯ ШАПКА ДЛЯ ВСЕХ ВКЛАДОК И ЭКРАНОВ ВНУТРИ BUYER SHELL
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
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _city,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Избранное'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Корзина'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}

class BuyerDrawer extends StatelessWidget {
  const BuyerDrawer({super.key});

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'SkidKZ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Divider(height: 1),

                    _sectionTitle('Аккаунт'),
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Войти / Регистрация'),
                      subtitle: const Text('Заказы, избранное, бонусы'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/login');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: const Text('Мои заказы'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/buyer/profile');
                      },
                    ),

                    const Divider(height: 1),

                    _sectionTitle('Кабинеты'),
                    ListTile(
                      leading: const Icon(Icons.store_mall_directory_outlined),
                      title: const Text('Кабинет магазина'),
                      subtitle: const Text('Продажи, товары, заказы'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/cabinet');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.campaign_outlined),
                      title: const Text('Кабинет ванхуна'),
                      subtitle: const Text('Заработать на промокодах'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/cabinet');
                      },
                    ),

                    const Divider(height: 1),

                    _sectionTitle('Сервис'),
                    ListTile(
                      leading: const Icon(Icons.support_agent_outlined),
                      title: const Text('Поддержка'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('О приложении'),
                      onTap: () => Navigator.pop(context),
                    ),

                    const Spacer(),
                    const Divider(height: 1),

                    _sectionTitle('Для бизнеса'),
                    ListTile(
                      leading: const Icon(Icons.add_business_outlined),
                      title: const Text('Открыть магазин'),
                      subtitle: const Text('Как это работает'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: context.go('/info/seller');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: const Text('Подключиться как ванхун'),
                      subtitle: const Text('Условия и старт'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: context.go('/info/wanghong');
                      },
                    ),
                    const SizedBox(height: 12),
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
