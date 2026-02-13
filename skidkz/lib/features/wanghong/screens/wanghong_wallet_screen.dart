import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:gap/gap.dart';

/// Модель баланса кошелька
class WalletBalance {
  final double available; // доступно к выводу
  final double hold;      // в холде (ждем разблокировки)

  const WalletBalance({
    required this.available,
    required this.hold,
  });

  double get total => available + hold;
}

/// Провайдер для расчета баланса кошелька из заказов
final wanghongWalletProvider = StreamProvider.autoDispose<WalletBalance>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(const WalletBalance(available: 0, hold: 0));
  }

  return FirebaseFirestore.instance
      .collection('orders')
      .where('promoOwnerUid', isEqualTo: user.uid)
      .where('status', whereIn: ['paid', 'completed']) // только оплаченные/завершенные
      .snapshots()
      .map((snapshot) {
    double available = 0;
    double hold = 0;
    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      final order = OrderModel.fromDoc(doc);
      final earning = order.commissionAmount.toDouble();

      // Вычисляем дату разблокировки
      final holdDays = order.holdDaysSnapshot ?? 7;
      final createdAt = order.createdAt ?? now;
      final releaseDate = createdAt.add(Duration(days: holdDays));

      if (now.isAfter(releaseDate)) {
        // Средства разблокированы
        available += earning;
      } else {
        // Средства в холде
        hold += earning;
      }
    }

    return WalletBalance(available: available, hold: hold);
  });
});

class WanghongWalletScreen extends ConsumerWidget {
  const WanghongWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(wanghongWalletProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Кошелёк'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: walletAsync.when(
        data: (wallet) => _WalletContent(wallet: wallet),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка загрузки: $error'),
        ),
      ),
    );
  }
}

class _WalletContent extends StatelessWidget {
  final WalletBalance wallet;

  const _WalletContent({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final minBalance = 1000.0;
    final canWithdraw = (wallet.available - minBalance) > 0;
    final isEmpty = wallet.total == 0; // Проверяем, есть ли хоть что-то

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBalanceCard(wallet.available, wallet.hold),
          const Gap(24),
          
          // Подсказка если совсем пусто
          if (isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Поделитесь промокодом с покупателями, чтобы начать зарабатывать!',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!canWithdraw)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  Gap(12),
                  Expanded(
                    child: Text(
                      'Неснижаемый остаток 1 000 ₸',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canWithdraw ? () => _withdraw(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                'Запросить вывод',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double available, double hold) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'Доступно к выводу',
            style: TextStyle(color: Colors.grey),
          ),
          const Gap(8),
          Text(
            '${_formatPrice(available)} ₸',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('В холде', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Gap(4),
                    Text(
                      '${_formatPrice(hold)} ₸',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: Column(
                  children: [
                    const Text('Всего заработано', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Gap(4),
                    Text(
                      '${_formatPrice(available + hold)} ₸',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _withdraw(BuildContext context) {
    // TODO: Здесь должна быть логика создания заявки на вывод в Firestore
    // Например:
    // await FirebaseFirestore.instance.collection('withdrawal_requests').add({
    //   'userId': FirebaseAuth.instance.currentUser!.uid,
    //   'amount': wallet.available - 1000,
    //   'status': 'pending',
    //   'createdAt': FieldValue.serverTimestamp(),
    // });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заявка создана'),
        content: const Text('Средства поступят на карту в течение 24 часов.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }
}
