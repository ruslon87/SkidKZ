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

    // Calculate Earnings using new fields
    final totalEarnings = orders.fold(0.0, (sum, o) => sum + o.wanghunEarning);
    
    final now = DateTime.now();
    final holdEarnings = orders
        .where((o) => o.holdUntil.isAfter(now))
        .fold(0.0, (sum, o) => sum + o.wanghunEarning);
        
    final availableEarnings = orders
        .where((o) => o.holdUntil.isBefore(now) || o.holdUntil.isAtSameMomentAs(now))
        .fold(0.0, (sum, o) => sum + o.wanghunEarning);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кабинет рекомендателя'),
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
                    const Text('Ваш промокод', style: TextStyle(color: Colors.white70)),
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скопировано!')));
                          },
                          icon: const Icon(Icons.copy, color: Colors.white),
                        ),
                      ],
                    ),
                    const Gap(8),
                    const Text('Делитесь и получайте доход с каждой продажи', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // Balance Section
            Text('Баланс', style: Theme.of(context).textTheme.titleLarge),
            const Gap(16),
            Row(
              children: [
                Expanded(child: _BalanceCard(label: 'Всего', amount: totalEarnings, color: Colors.black)),
                const Gap(16),
                Expanded(child: _BalanceCard(label: 'В холде', amount: holdEarnings, color: Colors.orange)),
              ],
            ),
            const Gap(16),
            _BalanceCard(
              label: 'Доступно к выводу',
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
                child: const Text('Запросить выплату'),
              ),
            ),
            if (availableEarnings < 1000)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Мин. сумма: 1 000 ₸', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            const Gap(32),

            // Earnings List
            Text('История начислений', style: Theme.of(context).textTheme.titleLarge),
            const Gap(16),
            if (orders.isEmpty)
              const Text('Пока нет начислений', style: TextStyle(color: Colors.grey)),
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
        title: const Text('Запрос выплаты'),
        content: Text('Вывести ${NumberFormat.currency(symbol: '₸', decimalDigits: 0).format(amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запрос отправлен!')));
            },
            child: const Text('Подтвердить'),
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
    final earning = order.wanghunEarning;
    final isHold = order.holdUntil.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade50,
          child: const Icon(Icons.attach_money, color: Colors.purple),
        ),
        title: Text(order.product.name), // Fixed: product.title -> product.name
        subtitle: Text(DateFormat('d MMM y').format(order.createdAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${currencyFormatter.format(earning)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
            ),
            Text(
              isHold ? 'HOLD' : 'AVAILABLE',
              style: TextStyle(
                fontSize: 10, 
                color: isHold ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}