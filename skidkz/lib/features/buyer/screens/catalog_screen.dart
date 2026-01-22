import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider)
        .where((p) => p.status == ProductStatus.approved)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог SkidKZ'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск товаров...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {}, // Mock search
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductCard(product: product);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/buyer/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey.shade200,
                width: double.infinity,
                child: Center(
                  child: Text(
                    product.category.split(' ').last, // Use emoji from category
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Gap(4),
                  Text(
                    currencyFormatter.format(product.retailPrice),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Цена SkidKZ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}