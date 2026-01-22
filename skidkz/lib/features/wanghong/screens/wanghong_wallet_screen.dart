import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class WanghongWalletScreen extends ConsumerStatefulWidget {
  const WanghongWalletScreen({super.key});

  @override
  ConsumerState<WanghongWalletScreen> createState() => _WanghongWalletScreenState();
}

class _WanghongWalletScreenState extends ConsumerState<WanghongWalletScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(mockDatabaseProvider);
    final available = db.wanghongBalance;
    final hold = db.wanghongHold;
    final canWithdraw = (available - 1000) > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Кошелёк'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(available, hold),
            const Gap(24),
            if (!canWithdraw)
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
                onPressed: canWithdraw ? () => _withdraw(ref) : null,
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
                      '${_formatPrice(available + hold)} ₸', // Simplified logic
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

  void _withdraw(WidgetRef ref) {
    ref.read(mockDatabaseProvider).requestWithdrawal();
    setState(() {}); // Refresh UI
    
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
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }
}
