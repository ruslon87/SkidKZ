import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class BuyerShell extends StatelessWidget {
  final Widget child;
  const BuyerShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0; // /buyer/home and fallback
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

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      // AppBar не нужен — шапка рисуется в HomePage (синяя)
      drawer: const BuyerDrawer(),
      body: child,
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -------------------------
            // Header
            // -------------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'SkidKZ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const Divider(height: 1),

            // -------------------------
            // Аккаунт покупателя (MVP)
            // -------------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Аккаунт',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w700),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Войти / Регистрация'),
              subtitle: const Text('Заказы, избранное, бонусы'),
              onTap: () {
                Navigator.pop(context);
                context.go('/login'); // позже можно сделать /login?mode=buyer
              },
            ),

            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Мои заказы'),
              onTap: () {
                Navigator.pop(context);
                // MVP: если не залогинен — router всё равно отправит на /login, если ты сделаешь этот экран кабинетным.
                // Пока можно вести на профиль или просто заглушку.
                context.go('/buyer/profile');
              },
            ),

            const Divider(height: 1),

            // -------------------------
            // Кабинеты
            // -------------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Кабинеты',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w700),
              ),
            ),

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

            // -------------------------
            // Сервис
            // -------------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Сервис',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w700),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Поддержка'),
              onTap: () {
                Navigator.pop(context);
                // TODO: context.go('/support');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('О приложении'),
              onTap: () {
                Navigator.pop(context);
                // TODO: context.go('/about');
              },
            ),

            const Spacer(),

            // -------------------------
            // Всегда внизу: Для бизнеса
            // -------------------------
            const Divider(height: 1),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Для бизнеса',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w700),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: const Text('Открыть магазин'),
              subtitle: const Text('Как это работает'),
              onTap: () {
                Navigator.pop(context);
                // Рекомендация: сделать инфо-экран /info/seller и кнопку "Продолжить" -> /cabinet
                // TODO: context.go('/info/seller');
              },
            ),

            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Подключиться как ванхун'),
              subtitle: const Text('Условия и старт'),
              onTap: () {
                Navigator.pop(context);
                // Рекомендация: инфо-экран /info/wanghong
                // TODO: context.go('/info/wanghong');
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
