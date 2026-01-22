import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final orders = ref.watch(ordersProvider)
        .where((o) => o.buyerPhone == user?.phoneNumber)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: orders.isEmpty
          ? const Center(child: Text('У вас пока нет заказов'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _OrderCard(order: orders[index]);
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                Text(
                  DateFormat('d MMM y').format(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      order.product.category.split(' ').last,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.product.name, style: Theme.of(context).textTheme.bodyMedium),
                      const Gap(4),
                      Text(
                        currencyFormatter.format(order.customerPrice),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(order.status),
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.completed:
        return AppTheme.success;
      case OrderStatus.cancelled:
        return AppTheme.error;
    }
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