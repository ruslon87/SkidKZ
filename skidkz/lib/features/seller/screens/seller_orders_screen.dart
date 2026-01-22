import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final orders = ref.watch(ordersProvider)
        .where((o) => o.sellerId == user?.id)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Orders')),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _SellerOrderCard(order: orders[index]);
              },
            ),
    );
  }
}

class _SellerOrderCard extends ConsumerWidget {
  final Order order;

  const _SellerOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currencyFormatter.format(order.amount),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            Text('Product: ${order.product.title}'),
            if (order.promoCode != null)
              Text('Promo Used: ${order.promoCode}', style: const TextStyle(color: Colors.orange)),
            const Gap(12),
            if (order.product.type == ProductType.service && order.status == OrderStatus.paid)
              ElevatedButton.icon(
                onPressed: () {
                   ref.read(ordersProvider.notifier).updateOrderStatus(order.id, OrderStatus.fulfilled);
                },
                icon: const Icon(Icons.check),
                label: const Text('Mark as Fulfilled'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              )
            else
               Text('Status: ${order.status.name.toUpperCase()}', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
