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
      // ВАЖНО: без AppBar, чтобы не было белой шапки
      drawer: const AppDrawer(),
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

/// Drawer для общего режима (гость/покупатель)
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Text(
                'SkidKZ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const Divider(height: 1),

            // Покупателю
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Витрина'),
              onTap: () {
                Navigator.pop(context);
                context.go('/buyer/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Поддержка'),
              onTap: () => Navigator.pop(context),
            ),

            const Divider(height: 1),

            // Вход в кабинет (единая точка)
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Кабинет (магазин/ванхун/админ)'),
              subtitle: const Text('Войти или выбрать роль'),
              onTap: () {
                Navigator.pop(context);
                context.go('/cabinet'); // router сам отправит на /login если надо
              },
            ),

            const Divider(height: 1),

            // Роли (позже привяжешь к маршрутам регистрации/логина)
            ListTile(
              leading: const Icon(Icons.store_mall_directory_outlined),
              title: const Text('Стать магазином'),
              subtitle: const Text('Регистрация продавца'),
              onTap: () {
                Navigator.pop(context);
                // TODO: context.go('/seller/register');
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Войти как магазин'),
              onTap: () {
                Navigator.pop(context);
                // TODO: context.go('/login?seller=1');
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Стать ванхуном'),
              subtitle: const Text('Регистрация создателя'),
              onTap: () {
                Navigator.pop(context);
                // TODO: context.go('/wanghong/register');
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Войти как ванхун'),
              onTap: () {
                Navigator.pop(context);
                // TODO: context.go('/login?wanghong=1');
              },
            ),

            const Divider(height: 1),

            // Клиент отдельно
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Войти как клиент'),
              onTap: () {
                Navigator.pop(context);
                // TODO: context.go('/buyer/login'); или общий /login с параметром
              },
            ),

            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Вы не авторизованы',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
