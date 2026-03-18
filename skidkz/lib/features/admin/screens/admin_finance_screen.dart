// lib/features/admin/screens/admin_finance_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _processPayment(BuildContext context, String uid, String promoCode, double pendingBalance, String kaspiPhone) async {
    if (pendingBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет средств для выплаты'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтвердить выплату'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentRow(label: 'Промокод', value: promoCode),
            _PaymentRow(label: 'Сумма', value: '${pendingBalance.toStringAsFixed(0)} ₸'),
            _PaymentRow(label: 'Kaspi', value: kaspiPhone.isNotEmpty ? kaspiPhone : 'не указан'),
            const SizedBox(height: 8),
            if (kaspiPhone.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Text('⚠️ Номер Kaspi не указан. Выплата будет отмечена как выполненная.', style: TextStyle(fontSize: 12, color: Colors.orange)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выплатить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      batch.update(userRef, {
        'profiles.wanghong.pendingBalance': 0,
        'profiles.wanghong.totalPaid': FieldValue.increment(pendingBalance),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final payoutRef = FirebaseFirestore.instance.collection('payouts').doc();
      batch.set(payoutRef, {
        'uid': uid,
        'promoCode': promoCode,
        'amount': pendingBalance,
        'kaspiPhone': kaspiPhone,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'processedBy': 'admin',
      });
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Выплата ${pendingBalance.toStringAsFixed(0)} ₸ выполнена'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Финансы'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Выплаты партнёрам'),
            Tab(text: 'История заказов'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PayoutsTab(onProcessPayment: _processPayment),
          const _OrdersTab(),
        ],
      ),
    );
  }
}

class _PayoutsTab extends StatelessWidget {
  final Future<void> Function(BuildContext, String, String, double, String) onProcessPayment;
  const _PayoutsTab({required this.onProcessPayment});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('roles', arrayContains: 'wanghong')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          // Fallback: try with single role field
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'wanghong')
                .snapshots(),
            builder: (context, snap2) {
              if (!snap2.hasData) return const Center(child: CircularProgressIndicator());
              return _buildPayoutsList(context, snap2.data?.docs ?? []);
            },
          );
        }
        return _buildPayoutsList(context, snap.data?.docs ?? []);
      },
    );
  }

  Widget _buildPayoutsList(BuildContext context, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Нет партнёров', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    double totalPending = 0;
    for (final doc in docs) {
      final data = doc.data();
      final profilesRaw = data['profiles'];
      final profiles = (profilesRaw is Map) ? profilesRaw.cast<String, dynamic>() : <String, dynamic>{};
      final wanghongRaw = profiles['wanghong'];
      final wanghong = (wanghongRaw is Map) ? wanghongRaw.cast<String, dynamic>() : <String, dynamic>{};
      totalPending += (wanghong['pendingBalance'] as num?)?.toDouble() ?? 0.0;
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Всего к выплате', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${totalPending.toStringAsFixed(0)} ₸', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final uid = data['uid']?.toString() ?? docs[index].id;
              final phone = data['phone']?.toString() ?? '-';
              final profilesRaw = data['profiles'];
              final profiles = (profilesRaw is Map) ? profilesRaw.cast<String, dynamic>() : <String, dynamic>{};
              final wanghongRaw = profiles['wanghong'];
              final wanghong = (wanghongRaw is Map) ? wanghongRaw.cast<String, dynamic>() : <String, dynamic>{};
              final buyerRaw = profiles['buyer'];
              final buyer = (buyerRaw is Map) ? buyerRaw.cast<String, dynamic>() : <String, dynamic>{};
              final firstName = buyer['firstName']?.toString() ?? '';
              final lastName = buyer['lastName']?.toString() ?? '';
              final fullName = '$firstName $lastName'.trim();
              final promoCode = wanghong['promoCode']?.toString() ?? '-';
              final pendingBalance = (wanghong['pendingBalance'] as num?)?.toDouble() ?? 0.0;
              final totalEarnings = (wanghong['totalEarnings'] as num?)?.toDouble() ?? 0.0;
              final totalPaid = (wanghong['totalPaid'] as num?)?.toDouble() ?? 0.0;
              final kaspiPhone = buyer['kaspiPhone']?.toString() ?? wanghong['kaspiPhone']?.toString() ?? '';
              final hasPending = pendingBalance > 0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: hasPending ? Colors.green.shade200 : AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.purple.shade50,
                          child: Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName.isNotEmpty ? fullName : phone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('Промокод: $promoCode', style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (hasPending)
                          ElevatedButton(
                            onPressed: () => onProcessPayment(context, uid, promoCode, pendingBalance, kaspiPhone),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Выплатить', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _FinanceCard(label: 'К выплате', value: '${pendingBalance.toStringAsFixed(0)} ₸', color: hasPending ? Colors.green : Colors.grey),
                        const SizedBox(width: 8),
                        _FinanceCard(label: 'Заработано', value: '${totalEarnings.toStringAsFixed(0)} ₸', color: Colors.blue),
                        const SizedBox(width: 8),
                        _FinanceCard(label: 'Выплачено', value: '${totalPaid.toStringAsFixed(0)} ₸', color: Colors.purple),
                      ],
                    ),
                    if (kaspiPhone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Kaspi: $kaspiPhone', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text('⚠️ Kaspi не указан', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _filter = 'all';

  String _statusLabel(String s) {
    switch (s) {
      case 'created': return 'Создан';
      case 'submitted': return 'Подтверждён';
      case 'paid': return 'Оплачен';
      case 'completed': return 'Завершён';
      case 'cancelled': return 'Отменён';
      case 'refunded': return 'Возврат';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'created': return Colors.blue;
      case 'submitted': return Colors.orange;
      case 'paid': return Colors.green;
      case 'completed': return Colors.teal;
      case 'cancelled': return Colors.red;
      case 'refunded': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);
    if (_filter != 'all') {
      query = query.where('status', isEqualTo: _filter);
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(label: 'Все', selected: _filter == 'all', color: AppTheme.primary, onTap: () => setState(() => _filter = 'all')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Оплачен', selected: _filter == 'paid', color: Colors.green, onTap: () => setState(() => _filter = 'paid')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Завершён', selected: _filter == 'completed', color: Colors.teal, onTap: () => setState(() => _filter = 'completed')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Отменён', selected: _filter == 'cancelled', color: Colors.red, onTap: () => setState(() => _filter = 'cancelled')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('Нет заказов', style: TextStyle(color: AppTheme.textSecondary)));
              }
              double totalRevenue = 0;
              double totalMargin = 0;
              for (final doc in docs) {
                final data = doc.data();
                totalRevenue += (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
                totalMargin += (data['totalMargin'] as num?)?.toDouble() ?? 0.0;
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(child: _SummaryCard(label: 'Выручка', value: '${totalRevenue.toStringAsFixed(0)} ₸', color: AppTheme.primary)),
                        const SizedBox(width: 10),
                        Expanded(child: _SummaryCard(label: 'Маржа', value: '${totalMargin.toStringAsFixed(0)} ₸', color: Colors.green)),
                        const SizedBox(width: 10),
                        Expanded(child: _SummaryCard(label: 'Заказов', value: '${docs.length}', color: Colors.blue)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final status = data['status']?.toString() ?? 'created';
                        final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
                        final totalMarginItem = (data['totalMargin'] as num?)?.toDouble() ?? 0.0;
                        final promoCode = data['promoCode']?.toString() ?? '';
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                        final itemsRaw = data['items'];
                        final itemsCount = (itemsRaw is List) ? itemsRaw.length : 0;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                        if (promoCode.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text('🏷 $promoCode', style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('$itemsCount товар(а)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                    if (createdAt != null)
                                      Text('${createdAt.day}.${createdAt.month}.${createdAt.year}', style: TextStyle(color: AppTheme.textDisabled, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${totalPrice.toStringAsFixed(0)} ₸', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  Text('маржа: ${totalMarginItem.toStringAsFixed(0)} ₸', style: TextStyle(color: Colors.green.shade700, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinanceCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  const _PaymentRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({required this.label, required this.selected, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppTheme.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}
