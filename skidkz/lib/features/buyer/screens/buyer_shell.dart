// lib/features/buyer/screens/buyer_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/features/common/widgets/skid_drawer.dart';

class BuyerShell extends StatelessWidget {
  const BuyerShell({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(String location) {
    if (location.startsWith('/buyer/home')) return 0;
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0;
  }

  void _goByIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/buyer/home');
        return;
      case 1:
        context.go('/buyer/catalog');
        return;
      case 2:
        context.go('/buyer/favorites');
        return;
      case 3:
        context.go('/buyer/cart');
        return;
      case 4:
        context.go('/buyer/profile');
        return;
      default:
        context.go('/buyer/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      drawer: const SkidDrawer(),

      appBar: AppBar(
        title: const Text('SkidKZ'),
        // ВАЖНО: никаких кнопок "Кабинет" тут больше нет.
      ),

      body: child,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => _goByIndex(context, i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Магазин',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Каталог',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Корзина',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
