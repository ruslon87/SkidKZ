import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final products = ref.watch(productsProvider)
        .where((p) => p.sellerId == user?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои товары'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/seller/products/add'),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: products.isEmpty
          ? const Center(child: Text('Нет товаров. Добавьте первый!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _SellerProductCard(product: products[index]);
              },
            ),
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  final Product product;

  const _SellerProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(product.categoryIcon, style: const TextStyle(fontSize: 30)),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title, style: Theme.of(context).textTheme.titleMedium),
                      const Gap(4),
                      Text(
                        'Розница: ${currencyFormatter.format(product.retailPrice)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'SkidKZ: ${currencyFormatter.format(product.skidkzPrice)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: product.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProductStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case ProductStatus.draft:
        color = Colors.grey;
        text = 'Черновик';
        break;
      case ProductStatus.pending:
        color = Colors.orange;
        text = 'Модерация';
        break;
      case ProductStatus.approved:
        color = AppTheme.success;
        text = 'Активен';
        break;
      case ProductStatus.rejected:
        color = AppTheme.error;
        text = 'Отклонён';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}