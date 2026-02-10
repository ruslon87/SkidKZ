import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product.dart';
import 'package:skidkz/features/home/providers/home_products_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _refresh() async {
    ref.invalidate(activeProductsStreamProvider);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsStreamProvider);
    final loading = productsAsync.isLoading;
    final products = productsAsync.asData?.value ?? const <Product>[];

    const city = 'Алматы';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            /// ---------------- HEADER ----------------
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.elevated,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              titleSpacing: 0,
              title: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu),
                          color: AppTheme.textPrimary,
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'SkidKZ',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on_outlined,
                          color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        city,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(68),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _SearchBar(),
                ),
              ),
            ),

            /// ---------------- CONTENT ----------------
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
              child: _SectionTitle(title: 'Вас могут заинтересовать'),
            ),

            if (loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              )
            else if (products.isEmpty)
              const SliverToBoxAdapter(child: _EmptyProductsState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ProductCard(product: products[i]),
                    childCount: products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ================= SEARCH =================
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: const [
          SizedBox(width: 12),
          Icon(Icons.search, color: AppTheme.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Поиск',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.tune, color: AppTheme.textDisabled),
          SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// ================= BANNERS =================
class _BannersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: const [
          Expanded(child: _BannerCard(text: 'Скидки')),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// ================= CATEGORIES =================
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
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
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Icon(item.icon, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// ================= TITLES =================
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// ================= EMPTY =================
class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Text(
          'Пока нет товаров',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// ================= PRODUCT CARD (FINTECH) =================
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  String _formatMoney(int v) {
    // 1234567 -> 1 234 567 ₸
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
    final cover = product.coverUrl ??
        (product.images.isNotEmpty ? product.images.first.url : null);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Media
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: AppTheme.background,
                  child: (cover == null || cover.isEmpty)
                      ? const Center(
                          child: Icon(Icons.image_outlined,
                              color: AppTheme.textDisabled),
                        )
                      : Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: AppTheme.textDisabled),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    _formatMoney(product.retailPrice),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // Margin pill (emerald 10–14% opacity)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                  ),
                  child: Text(
                    'Маржа ${_formatMoney(product.margin)}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Sub meta (optional)
            Row(
              children: const [
                Icon(Icons.verified_outlined, size: 14, color: AppTheme.textDisabled),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Проверено',
                    style: TextStyle(
                      color: AppTheme.textDisabled,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
