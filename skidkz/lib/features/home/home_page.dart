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
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsStreamProvider);
    final loading = productsAsync.isLoading;
    final products = productsAsync.asData?.value ?? const <Product>[];

    const city = 'Алматы';

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.elevated,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.elevated,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'SkidKZ',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.location_on_outlined,
                        color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    const Text(
                      city,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(68),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _SearchBar(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: _BannersRow()),
            const SliverToBoxAdapter(child: _CategoriesRow()),
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Вы недавно смотрели', action: 'Смотреть все'),
            ),
            const SliverToBoxAdapter(child: _RecentlyViewedPlaceholder()),
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Вас могут заинтересовать'),
            ),

            if (loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (products.isEmpty)
              const SliverToBoxAdapter(child: _EmptyProductsState())
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
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: const [
              Icon(Icons.search, color: AppTheme.textDisabled),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Поиск в магазине',
                  style: TextStyle(color: AppTheme.textDisabled),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.tune, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
