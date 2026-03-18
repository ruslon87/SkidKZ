// lib/features/buyer/screens/buyer_orders_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.created: return Colors.blue;
      case OrderStatus.confirmed: return Colors.orange;
      case OrderStatus.shipped: return Colors.purple;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.created: return 'Создан';
      case OrderStatus.confirmed: return 'Подтверждён';
      case OrderStatus.shipped: return 'Отправлен';
      case OrderStatus.delivered: return 'Доставлен';
      case OrderStatus.cancelled: return 'Отменён';
      default: return s.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мои заказы')),
        body: const Center(child: Text('Войдите, чтобы видеть заказы')),
      );
    }
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerUid', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Ошибка: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textDisabled),
                  const SizedBox(height: 16),
                  Text('Заказов пока нет', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          final orders = docs.map((d) => OrderModel.fromDoc(d)).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final order = orders[i];
              final statusColor = _statusColor(order.status);
              final dateStr = order.createdAt != null
                  ? DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt!)
                  : '—';
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Заказ #${order.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_statusLabel(order.status),
                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(dateStr, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const Divider(height: 20),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('${item.titleSnapshot} × ${item.qty}',
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                            Text(formatter.format(item.lineRetail),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      )),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Итого:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(formatter.format(order.totalRetail),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                        ],
                      ),
                      if (order.promoCodeUpper != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.local_offer, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('Промокод: ${order.promoCodeUpper}',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
