// lib/features/seller/screens/seller_orders_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  String _filter = 'all';

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.created: return 'Новый';
      case OrderStatus.submitted: return 'Подтверждён';
      case OrderStatus.paid: return 'Оплачен';
      case OrderStatus.completed: return 'Выполнен';
      case OrderStatus.cancelled: return 'Отменён';
      case OrderStatus.refunded: return 'Возврат';
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.created: return Colors.blue;
      case OrderStatus.submitted: return Colors.orange;
      case OrderStatus.paid: return Colors.purple;
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      case OrderStatus.refunded: return Colors.grey;
    }
  }

  List<OrderStatus> _nextStatuses(OrderStatus current) {
    switch (current) {
      case OrderStatus.created: return [OrderStatus.submitted, OrderStatus.cancelled];
      case OrderStatus.submitted: return [OrderStatus.paid, OrderStatus.cancelled];
      case OrderStatus.paid: return [OrderStatus.completed];
      case OrderStatus.completed: return [];
      case OrderStatus.cancelled: return [];
      case OrderStatus.refunded: return [];
    }
  }

  Future<void> _updateStatus(String orderId, OrderStatus newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus.name, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Войдите')));
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Фильтры
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'Все', value: 'all', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Новые', value: 'created', selected: _filter == 'created', onTap: () => setState(() => _filter = 'created')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Подтверждённые', value: 'confirmed', selected: _filter == 'confirmed', onTap: () => setState(() => _filter = 'confirmed')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Отправленные', value: 'shipped', selected: _filter == 'shipped', onTap: () => setState(() => _filter = 'shipped')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Доставленные', value: 'delivered', selected: _filter == 'delivered', onTap: () => setState(() => _filter = 'delivered')),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('sellerUid', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snap.data!.docs;
                if (_filter != 'all') {
                  docs = docs.where((d) => (d.data()['status'] as String?) == _filter).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textDisabled),
                        const SizedBox(height: 12),
                        Text('Заказов нет', style: TextStyle(color: AppTheme.textSecondary)),
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
                    final nextStatuses = _nextStatuses(order.status);

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
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            const SizedBox(height: 6),
                            Text(dateStr, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const Divider(height: 16),
                            ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${item.titleSnapshot} × ${item.qty}', style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  Text(formatter.format(item.lineRetail), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            )),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Итого:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(formatter.format(order.totalRetail),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                              ],
                            ),
                            if (order.promoCodeUpper != null) ...[
                              const SizedBox(height: 6),
                              Text('Промокод: ${order.promoCodeUpper}',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                            if (nextStatuses.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: nextStatuses.map((s) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ElevatedButton(
                                    onPressed: () => _updateStatus(order.id, s),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: s == OrderStatus.cancelled ? Colors.red : AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(_statusLabel(s), style: const TextStyle(fontSize: 12)),
                                  ),
                                )).toList(),
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
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}
