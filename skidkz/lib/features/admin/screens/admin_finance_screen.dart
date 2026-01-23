import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    final totalMargin = orders.fold<double>(
      0,
      (sum, o) => sum + o.margin,
    );

    final platformEarning = orders.fold<double>(
      0,
      (sum, o) => sum + o.platformEarning,
    );

    final wanghunEarning = orders.fold<double>(
      0,
      (sum, o) => sum + o.wanghunEarning,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансы платформы'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatCard(
              title: 'Общая маржа',
              value: formatter.format(totalMargin),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Доход платформы',
              value: formatter.format(platformEarning),
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Доход ванхунов',
              value: formatter.format(wanghunEarning),
              color: Colors.purple,
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
