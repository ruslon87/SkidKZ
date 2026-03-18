// lib/features/admin/screens/admin_home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Панель администратора',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary)),
            Text('Управление платформой SkidKZ',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),

            // Общая статистика
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                  builder: (context, ordersSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').snapshots(),
                      builder: (context, productsSnap) {
                        final usersCount = usersSnap.data?.docs.length ?? 0;
                        final ordersCount = ordersSnap.data?.docs.length ?? 0;
                        final productsCount = productsSnap.data?.docs.length ?? 0;

                        int totalRevenue = 0;
                        int totalMargin = 0;
                        for (final doc in ordersSnap.data?.docs ?? []) {
                          final data = doc.data() as Map<String, dynamic>;
                          if ((data['status'] as String?) == 'delivered') {
                            totalRevenue += (data['totalRetail'] as int?) ?? 0;
                            totalMargin += (data['totalMargin'] as int?) ?? 0;
                          }
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _AdminStatCard(icon: Icons.people, color: Colors.blue, label: 'Пользователей', value: '$usersCount', onTap: () => context.push('/admin/users'))),
                                const SizedBox(width: 12),
                                Expanded(child: _AdminStatCard(icon: Icons.inventory_2, color: Colors.purple, label: 'Товаров', value: '$productsCount', onTap: () => context.push('/admin/moderation'))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _AdminStatCard(icon: Icons.receipt_long, color: Colors.orange, label: 'Заказов', value: '$ordersCount', onTap: () => context.push('/admin/finance'))),
                                const SizedBox(width: 12),
                                Expanded(child: _AdminStatCard(icon: Icons.account_balance, color: Colors.green, label: 'Выручка', value: formatter.format(totalRevenue))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up, color: Colors.green, size: 28),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Прибыль платформы',
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      Text(formatter.format(totalMargin),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                              color: Colors.green)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Быстрые действия
            Text('Управление',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _AdminMenuItem(
              icon: Icons.people_outline,
              color: Colors.blue,
              title: 'Пользователи',
              subtitle: 'Управление ролями и аккаунтами',
              onTap: () => context.push('/admin/users'),
            ),
            const SizedBox(height: 8),
            _AdminMenuItem(
              icon: Icons.verified_outlined,
              color: Colors.purple,
              title: 'Модерация товаров',
              subtitle: 'Проверка и публикация товаров',
              onTap: () => context.push('/admin/moderation'),
            ),
            const SizedBox(height: 8),
            _AdminMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.green,
              title: 'Финансы',
              subtitle: 'Заказы, холды и выплаты партнёрам',
              onTap: () => context.push('/admin/finance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _AdminStatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    fontSize: 18,
                    color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(subtitle,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
