import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:intl/intl.dart';

class WanghongDealsScreen extends ConsumerWidget {
  const WanghongDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrders = ref.watch(mockDatabaseProvider).orders;
    final myDeals = allOrders.where((o) => o.promoCode == 'IVAN25').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Сделки'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: myDeals.isEmpty
          ? const Center(child: Text('Пока нет сделок по вашему коду'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: myDeals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final deal = myDeals[index];
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
                            Text(
                              deal.product.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'HOLD 14 дней',
                                style: TextStyle(
                                  color: Colors.orange,
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
                            const Text(
                              '+ 9 000 ₸',
                              style: TextStyle(
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
                              DateFormat('dd.MM.yyyy').format(deal.createdAt),
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                            Text(
                              'Разблок: ${DateFormat('dd.MM').format(deal.createdAt.add(const Duration(days: 14)))}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
