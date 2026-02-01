import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/features/home/home_page.dart';

class BuyerShell extends StatefulWidget {
  const BuyerShell({super.key});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(), // витрина
      const _PlaceholderPage(title: 'Каталог'),
      const _PlaceholderPage(title: 'Избранное'),
      const _PlaceholderPage(title: 'Корзина'),
      const _PlaceholderPage(title: 'Профиль'),
    ];

    return Scaffold(
      // ВАЖНО: AppBar НЕ ДЕЛАЕМ (чтобы не было белой шапки)
      drawer: const AppDrawer(), // ЕДИНЫЙ drawer для "общего приложения"
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
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
              child: Text('SkidKZ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const Divider(height: 1),

            // Покупателю
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Витрина'),
              onTap: () {
                Navigator.pop(context); // закрыть drawer
                // Витрина — это вкладка 0. В реальном проекте можно прокинуть callback.
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Поддержка'),
              onTap: () => Navigator.pop(context),
            ),

            const Divider(height: 1),

            // Роли (как ты хотел)
            ListTile(
              leading: const Icon(Icons.store_mall_directory_outlined),
              title: const Text('Стать магазином'),
              subtitle: const Text('Регистрация продавца'),
              onTap: () {
                Navigator.pop(context);
                // TODO: go to seller register route
                // context.go('/seller/register');
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Войти как магазин'),
              onTap: () {
                Navigator.pop(context);
                // TODO: go to seller login route
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Стать ванхуном'),
              subtitle: const Text('Регистрация создателя'),
              onTap: () {
                Navigator.pop(context);
                // TODO: go to wanghong register route
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Войти как ванхун'),
              onTap: () {
                Navigator.pop(context);
                // TODO: go to wanghong login route
              },
            ),

            const Divider(height: 1),

            // Клиент отдельно
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Войти как клиент'),
              onTap: () {
                Navigator.pop(context);
                // TODO: go to buyer login route
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

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
