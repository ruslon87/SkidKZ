import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

class WanghongHomeScreen extends ConsumerWidget {
  const WanghongHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final orders = ref.watch(ordersProvider)
        .where((o) => o.promoCode == user?.promoCode)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Calculate Earnings (Mock 10% commission)
    final totalEarnings = orders.fold(0.0, (sum, o) => sum + (o.amount * 0.1));
    final holdEarnings = orders
        .where((o) => o.earningStatus == EarningStatus.hold)
        .fold(0.0, (sum, o) => sum + (o.amount * 0.1));
    final availableEarnings = orders
        .where((o) => o.earningStatus == EarningStatus.available)
        .fold(0.0, (sum, o) => sum + (o.amount * 0.1));


    return Scaffold(
      appBar: AppBar(
        title: const Text('Wanghong Dashboard'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Promo Code Card
            Card(
              color: Colors.purple,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Your Promo Code', style: TextStyle(color: Colors.white70)),
                    const Gap(8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user?.promoCode ?? '...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user?.promoCode ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                          },
                          icon: const Icon(Icons.copy, color: Colors.white),
                        ),
                      ],
                    ),
                    const Gap(8),
                    const Text('Share to earn 10% from each sale', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // Balance Section
            Text('Balance', style: Theme.of(context).textTheme.titleLarge),
            const Gap(16),
            Row(
              children: [
                Expanded(child: _BalanceCard(label: 'Total', amount: totalEarnings, color: Colors.black)),
                const Gap(16),
                Expanded(child: _BalanceCard(label: 'On Hold', amount: holdEarnings, color: Colors.orange)),
              ],
            ),
            const Gap(16),
            _BalanceCard(
              label: 'Available for Payout',
              amount: availableEarnings,
              color: AppTheme.success,
              action: ElevatedButton(
                onPressed: availableEarnings >= 1000 
                  ? () => _requestPayout(context, availableEarnings)
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Request Payout'),
              ),
            ),
            if (availableEarnings < 1000)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Min. payout: 1,000 ₸', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            const Gap(32),

            // Earnings List
            Text('Recent Earnings', style: Theme.of(context).textTheme.titleLarge),
            const Gap(16),
            ...orders.map((o) => _EarningItem(order: o)),
          ],
        ),
      ),
    );
  }

  void _requestPayout(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payout Request'),
        content: Text('Request payout of ${NumberFormat.currency(symbol: '₸', decimalDigits: 0).format(amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted!')));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final Widget? action;

  const _BalanceCard({required this.label, required this.amount, required this.color, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const Gap(8),
          Text(
            currencyFormatter.format(amount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action != null) ...[
            const Gap(16),
            SizedBox(width: double.infinity, child: action!),
          ],
        ],
      ),
    );
  }
}

class _EarningItem extends StatelessWidget {
  final Order order;

  const _EarningItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final earning = order.amount * 0.1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade50,
          child: const Icon(Icons.attach_money, color: Colors.purple),
        ),
        title: Text(order.product.title),
        subtitle: Text(DateFormat('MMM d, y').format(order.createdAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${currencyFormatter.format(earning)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
            ),
            Text(
              order.earningStatus.name.toUpperCase(),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
