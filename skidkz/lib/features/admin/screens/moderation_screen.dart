import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Модерация'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Товары'),
              Tab(text: 'Продавцы'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _ProductModerationList(),
            Center(child: Text('Нет заявок от продавцов')),
          ],
        ),
      ),
    );
  }
}

class _ProductModerationList extends ConsumerWidget {
  const _ProductModerationList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider)
        .where((p) => p.status == ProductStatus.pending)
        .toList();

    if (products.isEmpty) {
      return const Center(child: Text('Нет товаров на модерации'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _ModerationCard(product: products[index]);
      },
    );
  }
}

class _ModerationCard extends ConsumerWidget {
  final Product product;

  const _ModerationCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.isService ? 'УСЛУГА' : 'ТОВАР',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Text(product.name, style: Theme.of(context).textTheme.titleMedium),
            Text(product.category),
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Розница', style: TextStyle(color: Colors.grey)),
                    Text(currencyFormatter.format(product.retailPrice)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SkidKZ', style: TextStyle(color: Colors.grey)),
                    Text(currencyFormatter.format(product.skidkzPrice), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Выплата продавцу', style: TextStyle(color: Colors.grey)),
                    Text(currencyFormatter.format(product.sellerPrice), style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(productsProvider.notifier).updateProductStatus(product.id, ProductStatus.rejected);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                    child: const Text('Отклонить'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                       ref.read(productsProvider.notifier).updateProductStatus(product.id, ProductStatus.approved);
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Товар одобрен')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    child: const Text('Одобрить'),
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