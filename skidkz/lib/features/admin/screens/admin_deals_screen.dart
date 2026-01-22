import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:intl/intl.dart';

class AdminDealsScreen extends ConsumerWidget {
  const AdminDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(mockDatabaseProvider).orders;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Все сделки'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Нет активных сделок'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.productName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${order.price} ₸',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Покупатель: Иван | Продавец: seller1', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        if (order.promoCode.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Ванхун: IVAN25 (+9 000 ₸)', style: TextStyle(fontSize: 12, color: Colors.purple.shade300)),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd.MM.yyyy HH:mm').format(order.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            TextButton(
                              onPressed: () {
                                // Cancel logic mock
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сделка отменена')));
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Отменить'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
