import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skidkz/data/product_repository.dart';
import 'package:skidkz/data/models/product.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ProductRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(FirebaseFirestore.instance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      drawer: const _SimpleDrawer(),
      body: StreamBuilder<List<Product>>(
        stream: _repo.watchActiveProducts(),
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          final products = snap.data ?? const <Product>[];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TopHeader(
                  city: 'Алматы',
                  onTapSearch: () {
                    // TODO: открыть поиск
                  },
                ),
              ),
              SliverToBoxAdapter(child: _BannersRow()),
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
              const SliverToBoxAdapter(
                child: _SectionTitle(title: 'Вы недавно смотрели', action: 'Смотреть все'),
              ),
              SliverToBoxAdapter(child: _RecentlyViewedPlaceholder()),
              const SliverToBoxAdapter(
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
                      // TODO: можно вести в кабинет продавца, если seller/admin
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
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.city,
    required this.onTapSearch,
  });

  final String city;
  final VoidCallback onTapSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2E6CF6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Меню',
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SkidKZ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.location_on_outlined, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                city,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
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
        ],
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
        children: const [
          Expanded(child: _BannerCard(text: 'Супер скидки')),
          SizedBox(width: 12),
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
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
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

class _SimpleDrawer extends StatelessWidget {
  const _SimpleDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _DrawerHeaderGuest(),
            const _DrawerSectionTitle('Аккаунт'),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Мои заказы'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: перейти в orders
              },
            ),
            const Divider(height: 24),

            const _DrawerSectionTitle('Кабинеты'),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Кабинет магазина'),
              subtitle: const Text('Продажи, товары, заказы'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: seller cabinet
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Кабинет ванхуна'),
              subtitle: const Text('Заработать на промокодах'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: wanghong cabinet
              },
            ),
            const Divider(height: 24),

            const _DrawerSectionTitle('Для бизнеса'),
            ListTile(
              leading: const Icon(Icons.add_business_outlined),
              title: const Text('Открыть магазин'),
              subtitle: const Text('Как это работает'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: open store flow
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title: const Text('Подключиться как ванхун'),
              subtitle: const Text('Условия и старт'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: join as wanghong
              },
            ),
            const Divider(height: 24),

            const _DrawerSectionTitle('Сервис'),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Поддержка'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: support
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeaderGuest extends StatelessWidget {
  const _DrawerHeaderGuest();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2E6CF6),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SkidKZ',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Войти / Регистрация\nЗаказы, избранное, бонусы',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('Гость', style: TextStyle(color: Colors.white70)),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
      ),
    );
  }
}
