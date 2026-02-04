import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'package:skidkz/data/product_repository.dart';
import 'package:skidkz/data/models/product.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ProductRepository _repo;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(FirebaseFirestore.instance);
  }

  Future<bool> _handleBack() async {
    // 1) Если drawer открыт — закрываем
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return false;
    }

    // 2) На главном: double back to exit
    final now = DateTime.now();
    final last = _lastBackPress;
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нажмите ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true; // разрешаем выход
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await _handleBack();
        if (shouldExit && mounted) {
          // Закрыть приложение (Android)
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF3F5F7),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF2E6CF6),
          title: const Text('SkidKZ'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: const [
                  Icon(Icons.location_on_outlined, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Алматы', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),

        // Оставляем ТОЛЬКО “кабинетный” drawer (как на твоем скрине)
        drawer: const _AccountDrawer(),

        body: StreamBuilder<List<Product>>(
          stream: _repo.watchActiveProducts(),
          builder: (context, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final products = snap.data ?? const <Product>[];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _TopSearchBlock(
                    onTapSearch: () {
                      // TODO: открыть поиск/каталог
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _BannersRow(),
                ),
                SliverToBoxAdapter(
                  child: _CategoriesRow(
                    categories: const [
                      _CategoryItem(icon: Icons.phone_android, label: 'Телефоны'),
                      _CategoryItem(icon: Icons.laptop_mac, label: 'Ноутбуки'),
                      _CategoryItem(icon: Icons.checkroom, label: 'Одежда'),
                      _CategoryItem(icon: Icons.home_outlined, label: 'Дом'),
                      _CategoryItem(icon: Icons.sports_soccer, label: 'Спорт'),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionTitle(title: 'Вы недавно смотрели', action: 'Смотреть все'),
                ),
                SliverToBoxAdapter(
                  child: _RecentlyViewedPlaceholder(),
                ),
                SliverToBoxAdapter(
                  child: _SectionTitle(title: 'Вас могут заинтересовать', action: null),
                ),
                if (loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (products.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyProductsState(
                      onCreateProductHint: () {
                        // TODO: можно открыть seller flow, если текущий пользователь seller/admin
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ProductCard(product: products[i]),
                        childCount: products.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopSearchBlock extends StatelessWidget {
  const _TopSearchBlock({required this.onTapSearch});

  final VoidCallback onTapSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2E6CF6),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTapSearch,
          child: Row(
            children: const [
              SizedBox(width: 12),
              Icon(Icons.search, color: Colors.black54),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Поиск в магазине',
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
              ),
              Icon(Icons.close, color: Colors.black26),
              SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Expanded(child: _BannerCard(text: 'Супер скидки')),
          const SizedBox(width: 12),
          Expanded(child: _BannerCard(text: 'Новинки')),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF8DB6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  const _CategoryItem({required this.icon, required this.label});
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.categories});
  final List<_CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.map((c) => _CategoryChip(item: c)).toList(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.item});
  final _CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          if (action != null)
            Text(
              action!,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

class _RecentlyViewedPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          return Container(
            width: 130,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.black26),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Товар (пример)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({required this.onCreateProductHint});
  final VoidCallback onCreateProductHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пока нет товаров',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Как только магазины добавят товары и они пройдут модерацию, они появятся здесь.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onCreateProductHint,
              child: const Text('Добавить первый товар (для продавца)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  String _formatMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(' ');
    }
    return '${buf.toString()} ₸';
  }

  @override
  Widget build(BuildContext context) {
    final cover = product.coverUrl ?? (product.images.isNotEmpty ? product.images.first.url : null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: const Color(0xFFF1F3F5),
                  child: cover == null || cover.isEmpty
                      ? const Icon(Icons.image_outlined, color: Colors.black26)
                      : Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined, color: Colors.black26),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              _formatMoney(product.retailPrice),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Маржа: ${_formatMoney(product.margin)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================
// Drawer "как на твоем скрине"
// ==============================

class _AccountDrawer extends StatelessWidget {
  const _AccountDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: const Color(0xFF2E6CF6),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SkidKZ',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: открыть экран входа/регистрации
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_outline, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Войти / Регистрация',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Заказы, избранное, бонусы',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  const Text('Гость', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const _DrawerSectionTitle('Аккаунт'),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Мои заказы'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: открыть "Мои заказы"
              },
            ),
            const _DrawerSectionTitle('Кабинеты'),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Кабинет магазина'),
              subtitle: const Text('Продажи, товары, заказы'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: открыть кабинет магазина
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Кабинет ванхуна'),
              subtitle: const Text('Заработать на промокодах'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: открыть кабинет ванхуна
              },
            ),
            const _DrawerSectionTitle('Для бизнеса'),
            ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: const Text('Открыть магазин'),
              subtitle: const Text('Как это работает'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: открыть онбординг продавца
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Подключиться как ванхун'),
              subtitle: const Text('Условия и старт'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: открыть онбординг ванхуна
              },
            ),
            const _DrawerSectionTitle('Сервис'),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Поддержка'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: открыть поддержку
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  const _DrawerSectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
