import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class BuyerRootShell extends StatefulWidget {
  const BuyerRootShell({super.key, required this.child});

  final Widget child;

  @override
  State<BuyerRootShell> createState() => _BuyerRootShellState();
}

class _BuyerRootShellState extends State<BuyerRootShell> {
  DateTime? _lastBackPress;

  int _indexFromLocation(String location) {
    if (location.startsWith('/buyer/catalog')) return 1;
    if (location.startsWith('/buyer/favorites')) return 2;
    if (location.startsWith('/buyer/cart')) return 3;
    if (location.startsWith('/buyer/profile')) return 4;
    return 0; // /buyer/home
  }

  String _locationForIndex(int index) {
    switch (index) {
      case 0:
        return '/buyer/home';
      case 1:
        return '/buyer/catalog';
      case 2:
        return '/buyer/favorites';
      case 3:
        return '/buyer/cart';
      case 4:
        return '/buyer/profile';
      default:
        return '/buyer/home';
    }
  }

  void _showExitHint() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        // 1) Если есть что закрыть в стеке — закрываем
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }

        // 2) Если мы НЕ на главной витрине — возвращаем на /buyer/home
        if (!location.startsWith('/buyer/home')) {
          context.go('/buyer/home');
          return;
        }

        // 3) Мы на /buyer/home: двойной Back для выхода
        final now = DateTime.now();
        final last = _lastBackPress;

        if (last == null || now.difference(last) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          _showExitHint();
          return;
        }

        _exitApp();
      },
      child: Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const ListTile(
                  title: Text('SkidKZ', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Меню'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Магазин'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/buyer/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.grid_view_outlined),
                  title: const Text('Каталог'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/buyer/catalog');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Избранное'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/buyer/favorites');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart_outlined),
                  title: const Text('Корзина'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/buyer/cart');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Профиль'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/buyer/profile');
                  },
                ),
              ],
            ),
          ),
        ),
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            final target = _locationForIndex(i);
            if (target == location) return;
            context.go(target);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              label: 'Магазин',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
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
      ),
    );
  }
}
