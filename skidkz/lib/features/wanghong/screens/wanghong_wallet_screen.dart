// lib/features/wanghong/screens/wanghong_wallet_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class WanghongWalletScreen extends StatelessWidget {
  const WanghongWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Войдите в систему')));
    }
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('promoOwnerUid', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;

            int availableBalance = 0;
            int holdBalance = 0;
            int totalPaid = 0;

            for (final doc in docs) {
              final data = doc.data();
              final margin = (data['totalMargin'] as int?) ?? 0;
              final bps = (data['commissionBpsSnapshot'] as int?) ?? 0;
              final holdDays = (data['holdDaysSnapshot'] as int?) ?? 7;
              final commission = (margin * bps) ~/ 10000;
              final status = (data['status'] as String?) ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final holdUntil = createdAt?.add(Duration(days: holdDays));
              final isHold = holdUntil?.isAfter(DateTime.now()) ?? true;

              if (status == 'delivered') {
                totalPaid += commission;
              } else if (status == 'cancelled') {
                // не считаем
              } else if (isHold) {
                holdBalance += commission;
              } else {
                availableBalance += commission;
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Кошелёк',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 16),

                // Основной баланс
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Доступно для вывода',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(formatter.format(availableBalance),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: availableBalance > 0
                              ? () => _showWithdrawDialog(context, availableBalance, formatter)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Вывести средства',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hold и выплачено
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        icon: Icons.lock_clock,
                        color: Colors.orange,
                        label: 'На холде',
                        value: formatter.format(holdBalance),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceCard(
                        icon: Icons.done_all,
                        color: Colors.blue,
                        label: 'Выплачено',
                        value: formatter.format(totalPaid),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // История сделок
                Text('История начислений',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 12),

                if (docs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 48, color: AppTheme.textDisabled),
                          const SizedBox(height: 12),
                          Text('Начислений пока нет',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  ...docs.map((doc) {
                    final data = doc.data();
                    final margin = (data['totalMargin'] as int?) ?? 0;
                    final bps = (data['commissionBpsSnapshot'] as int?) ?? 0;
                    final holdDays = (data['holdDaysSnapshot'] as int?) ?? 7;
                    final commission = (margin * bps) ~/ 10000;
                    final status = (data['status'] as String?) ?? '';
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();
                    final holdUntil =
                        createdAt?.add(Duration(days: holdDays));
                    final isHold = holdUntil?.isAfter(DateTime.now()) ?? true;
                    final dateStr = createdAt != null
                        ? DateFormat('dd.MM.yyyy').format(createdAt)
                        : '—';
                    final items = (data['items'] as List?) ?? [];
                    final firstTitle = items.isNotEmpty
                        ? (items.first as Map)['titleSnapshot'] ?? 'Товар'
                        : 'Товар';

                    Color statusColor;
                    String statusLabel;
                    if (status == 'cancelled') {
                      statusColor = Colors.red;
                      statusLabel = 'Отменён';
                    } else if (status == 'delivered') {
                      statusColor = Colors.green;
                      statusLabel = 'Выплачено';
                    } else if (isHold) {
                      statusColor = Colors.orange;
                      statusLabel = 'Холд до ${holdUntil != null ? DateFormat('dd.MM').format(holdUntil) : '?'}';
                    } else {
                      statusColor = Colors.teal;
                      statusLabel = 'Доступно';
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppTheme.divider),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.monetization_on,
                              color: statusColor, size: 20),
                        ),
                        title: Text(firstTitle.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('$dateStr · $statusLabel',
                            style: TextStyle(
                                color: statusColor, fontSize: 12)),
                        trailing: Text(
                          status == 'cancelled'
                              ? '—'
                              : '+ ${formatter.format(commission)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: status == 'cancelled'
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showWithdrawDialog(
      BuildContext context, int amount, NumberFormat formatter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Вывод средств'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Доступно: ${formatter.format(amount)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            const Text(
                'Для вывода средств свяжитесь с администратором платформы или дождитесь автоматической выплаты.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _BalanceCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
