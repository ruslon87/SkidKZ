import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/repositories/mock_database.dart';

class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    final double platformTotal = orders.fold<double>(
      0.0,
      (sum, o) => sum + (o.platformEarning),
    );

    final double wanghunTotal = orders.fold<double>(
      0.0,
      (sum, o) => sum + (o.wanghunEarning),
    );

    final double marginTotal = orders.fold<double>(
      0.0,
      (sum, o) => sum + (o.margin),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Финансы платформы'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatCard(
              title: 'Маржа всего',
              value: formatter.format(marginTotal),
              color: Colors.black87,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Заработок платформы (10%)',
              value: formatter.format(platformTotal),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Начислено ванхунам (90%)',
              value: formatter.format(wanghunTotal),
              color: Colors.purple,
            ),
            const SizedBox(height: 24),
            Text(
              'Источник: сумма по всем заказам из ordersProvider.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
