// lib/features/wanghong/screens/wanghong_home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class WanghongHomeScreen extends StatelessWidget {
  const WanghongHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Войдите в систему')));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data?.data() ?? {};
          final profiles = (data['profiles'] as Map<String, dynamic>?) ?? {};
          final wanghongProfile =
              (profiles['wanghong'] as Map<String, dynamic>?) ?? {};
          final promoCode =
              (wanghongProfile['promoCode'] as String?) ?? '';
          final commissionBps =
              (wanghongProfile['commissionBps'] as int?) ?? 1000;
          final commissionPct = commissionBps / 100;
          final displayName =
              (data['displayName'] as String?) ?? 'Партнёр';

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Приветствие
                  Text('Привет, $displayName! 👋',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Ваш партнёрский кабинет',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 20),

                  // Карточка промокода
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ваш промокод',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              promoCode.isEmpty ? 'НЕ НАЗНАЧЕН' : promoCode,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3),
                            ),
                            const Spacer(),
                            if (promoCode.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: promoCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Промокод скопирован!'),
                                        behavior: SnackBarBehavior.floating),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.copy,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Ваша комиссия: $commissionPct%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Статистика
                  _WanghongStats(uid: user.uid),
                  const SizedBox(height: 20),

                  // Как поделиться
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Как заработать?',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        _HowToItem(
                          icon: Icons.share,
                          color: Colors.blue,
                          title: 'Поделитесь товаром',
                          subtitle: 'Отправьте карточку товара друзьям в WhatsApp или Telegram',
                        ),
                        const SizedBox(height: 10),
                        _HowToItem(
                          icon: Icons.local_offer,
                          color: Colors.orange,
                          title: 'Дайте промокод',
                          subtitle: 'Покупатель вводит ваш промокод при оформлении заказа',
                        ),
                        const SizedBox(height: 10),
                        _HowToItem(
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
                          title: 'Получите комиссию',
                          subtitle: 'После подтверждения заказа деньги поступят на ваш баланс',
                        ),
                      ],
                    ),
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

class _HowToItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _HowToItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WanghongStats extends StatelessWidget {
  final String uid;
  const _WanghongStats({required this.uid});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('promoOwnerUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final orders = snap.data?.docs ?? [];
        int totalEarned = 0;
        int pendingEarned = 0;
        int totalOrders = orders.length;

        for (final doc in orders) {
          final data = doc.data();
          final margin = (data['totalMargin'] as int?) ?? 0;
          final bps = (data['commissionBpsSnapshot'] as int?) ?? 0;
          final commission = (margin * bps) ~/ 10000;
          final status = (data['status'] as String?) ?? '';
          if (status == 'delivered') {
            totalEarned += commission;
          } else if (status != 'cancelled') {
            pendingEarned += commission;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long,
                color: Colors.blue,
                label: 'Заказов',
                value: '$totalOrders',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.hourglass_empty,
                color: Colors.orange,
                label: 'В ожидании',
                value: formatter.format(pendingEarned),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                color: Colors.green,
                label: 'Заработано',
                value: formatter.format(totalEarned),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
