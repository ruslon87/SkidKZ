// lib/features/admin/screens/admin_finance_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансы'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;

          int totalRevenue = 0;
          int totalMargin = 0;
          int pendingPayouts = 0;
          int paidOut = 0;

          for (final doc in docs) {
            final data = doc.data();
            final status = (data['status'] as String?) ?? '';
            final retail = (data['totalRetail'] as int?) ?? 0;
            final margin = (data['totalMargin'] as int?) ?? 0;
            final bps = (data['commissionBpsSnapshot'] as int?) ?? 0;
            final commission = (margin * bps) ~/ 10000;
            final holdDays = (data['holdDaysSnapshot'] as int?) ?? 7;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final holdUntil = createdAt?.add(Duration(days: holdDays));
            final isHold = holdUntil?.isAfter(DateTime.now()) ?? true;

            if (status == 'delivered') {
              totalRevenue += retail;
              totalMargin += margin;
              paidOut += commission;
            } else if (status != 'cancelled' && !isHold) {
              pendingPayouts += commission;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Сводка
              Row(
                children: [
                  Expanded(child: _FinCard(label: 'Выручка', value: formatter.format(totalRevenue), color: Colors.blue, icon: Icons.payments)),
                  const SizedBox(width: 12),
                  Expanded(child: _FinCard(label: 'Прибыль', value: formatter.format(totalMargin), color: Colors.green, icon: Icons.trending_up)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _FinCard(label: 'К выплате', value: formatter.format(pendingPayouts), color: Colors.orange, icon: Icons.account_balance_wallet)),
                  const SizedBox(width: 12),
                  Expanded(child: _FinCard(label: 'Выплачено', value: formatter.format(paidOut), color: Colors.purple, icon: Icons.done_all)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Все заказы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final data = doc.data();
                final status = (data['status'] as String?) ?? '';
                final retail = (data['totalRetail'] as int?) ?? 0;
                final margin = (data['totalMargin'] as int?) ?? 0;
                final bps = (data['commissionBpsSnapshot'] as int?) ?? 0;
                final commission = (margin * bps) ~/ 10000;
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final dateStr = createdAt != null ? DateFormat('dd.MM.yy HH:mm').format(createdAt) : '—';
                final promoCode = data['promoCodeUpper'] as String?;

                Color statusColor;
                switch (status) {
                  case 'delivered': statusColor = Colors.green; break;
                  case 'cancelled': statusColor = Colors.red; break;
                  case 'shipped': statusColor = Colors.purple; break;
                  case 'confirmed': statusColor = Colors.orange; break;
                  default: statusColor = Colors.blue;
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppTheme.divider),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('#${doc.id.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(dateStr, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _FinRow(label: 'Сумма', value: formatter.format(retail)),
                            _FinRow(label: 'Маржа', value: formatter.format(margin)),
                            _FinRow(label: 'Комиссия партнёру', value: formatter.format(commission)),
                          ],
                        ),
                        if (promoCode != null) ...[
                          const SizedBox(height: 6),
                          Text('Промокод: $promoCode',
                              style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _FinCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _FinCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final String value;
  const _FinRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}
