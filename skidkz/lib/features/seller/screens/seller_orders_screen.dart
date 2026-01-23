import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show all orders as sellerId is removed from model
    final orders = ref.watch(ordersProvider)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Входящие заказы')),
      body: orders.isEmpty
          ? const Center(child: Text('Нет заказов'))
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
                  'Заказ #${order.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currencyFormatter.format(order.customerPrice),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            Text('Товар: ${order.product.name}'),
            if (order.promoCode != null)
              Text('Промокод: ${order.promoCode}', style: const TextStyle(color: Colors.orange)),
            
            const Gap(8),
            Text(
              'Ваша выплата: ${currencyFormatter.format(order.sellerPayout)}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),

            const Gap(12),
            if (order.product.isService && order.status == OrderStatus.paid)
              ElevatedButton.icon(
                onPressed: () {
                   ref.read(ordersProvider.notifier).updateOrderStatus(order.id, OrderStatus.completed);
                },
                icon: const Icon(Icons.check),
                label: const Text('Подтвердить выполнение'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              )
            else
               Text('Статус: ${_getStatusText(order.status)}', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return 'Оплачен';
      case OrderStatus.processing:
        return 'В обработке';
      case OrderStatus.completed:
        return 'Завершен';
      case OrderStatus.cancelled:
        return 'Отменен';
    }
  }
}