import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:intl/intl.dart';

/// Провайдер для получения заказов ванхуна (по промокоду)
final wanghongOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  // Получаем заказы, где promoOwnerUid == текущий пользователь
  return FirebaseFirestore.instance
      .collection('orders')
      .where('promoOwnerUid', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => OrderModel.fromDoc(doc))
        .toList();
  });
});

class WanghongDealsScreen extends ConsumerWidget {
  const WanghongDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(wanghongOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Сделки'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Пока нет сделок',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Когда покупатель использует ваш промокод,\nсделки появятся здесь',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _DealCard(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка загрузки: $error'),
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final OrderModel order;

  const _DealCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final holdDays = order.holdDaysSnapshot ?? 7;
    final holdUntil = order.createdAt?.add(Duration(days: holdDays)) ?? DateTime.now();
    final isHold = holdUntil.isAfter(DateTime.now());
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    // Название товара - берем из первого item
    final productName = order.items.isNotEmpty 
        ? order.items.first.titleSnapshot 
        : 'Товар';

    // Заработок ванхуна
    final earning = order.commissionAmount;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isHold)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'HOLD',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ДОСТУПНО',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ваша доля:',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  '+ ${formatter.format(earning)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.createdAt != null
                      ? DateFormat('dd.MM.yyyy').format(order.createdAt!)
                      : '—',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                Text(
                  'Разблок: ${DateFormat('dd.MM').format(holdUntil)}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
            if (order.promoCodeUpper != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_offer, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Промокод: ${order.promoCodeUpper}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
