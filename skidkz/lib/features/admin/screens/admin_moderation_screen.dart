// lib/features/admin/screens/admin_moderation_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  String _filter = 'pending';

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return 'На проверке';
      case 'active': return 'Одобрен';
      case 'rejected': return 'Отклонён';
      case 'archived': return 'Архив';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return Colors.orange;
      case 'active': return Colors.green;
      case 'rejected': return Colors.red;
      case 'archived': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Future<void> _approveProduct(String docId) async {
    await FirebaseFirestore.instance.collection('products').doc(docId).update({
      'status': 'active',
      'isActive': true,
      'moderatedAt': FieldValue.serverTimestamp(),
      'rejectionReason': null,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Товар одобрен и опубликован'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectProduct(BuildContext context, String docId, String productTitle) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отклонить товар'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Товар: "$productTitle"', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text('Укажите причину отклонения:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Например: некорректное описание, запрещённый товар...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim().isEmpty ? 'Не соответствует требованиям платформы' : reasonCtrl.text.trim()),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (confirmed != null) {
      await FirebaseFirestore.instance.collection('products').doc(docId).update({
        'status': 'rejected',
        'isActive': false,
        'moderatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': confirmed,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар отклонён'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showProductDetail(BuildContext context, String docId, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'Без названия';
    final description = data['description']?.toString() ?? '';
    final retailPrice = (data['retailPrice'] as num?)?.toDouble() ?? 0.0;
    final margin = (data['margin'] as num?)?.toDouble() ?? 0.0;
    final status = data['status']?.toString() ?? 'pending';
    final coverUrl = data['coverUrl']?.toString() ?? '';
    final sellerUid = data['sellerUid']?.toString() ?? '';
    final rejectionReason = data['rejectionReason']?.toString() ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              if (coverUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    coverUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor(status).withOpacity(0.3)),
                    ),
                    child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PriceCard(label: 'Цена продажи', value: '${retailPrice.toStringAsFixed(0)} ₸', color: AppTheme.primary),
                  const SizedBox(width: 10),
                  _PriceCard(label: 'Маржа', value: '${margin.toStringAsFixed(0)} ₸', color: Colors.green),
                  const SizedBox(width: 10),
                  _PriceCard(label: 'Себестоимость', value: '${(retailPrice - margin).toStringAsFixed(0)} ₸', color: Colors.grey),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Описание', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Информация', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 8),
                    if (sellerUid.isNotEmpty) _InfoRow(label: 'UID продавца', value: sellerUid),
                    if (createdAt != null) _InfoRow(label: 'Создан', value: '${createdAt.day}.${createdAt.month}.${createdAt.year}'),
                  ],
                ),
              ),
              if (rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Причина отклонения', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(rejectionReason, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (status == 'pending' || status == 'rejected') ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _approveProduct(docId);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Одобрить и опубликовать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (status == 'pending' || status == 'active')
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _rejectProduct(context, docId, title);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Отклонить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Модерация товаров'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: 'На проверке', selected: _filter == 'pending', color: Colors.orange, onTap: () => setState(() => _filter = 'pending')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Одобренные', selected: _filter == 'active', color: Colors.green, onTap: () => setState(() => _filter = 'active')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Отклонённые', selected: _filter == 'rejected', color: Colors.red, onTap: () => setState(() => _filter = 'rejected')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Архив', selected: _filter == 'archived', color: Colors.grey, onTap: () => setState(() => _filter = 'archived')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('status', isEqualTo: _filter)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Ошибка: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'pending' ? 'Нет товаров на проверке' : 'Нет товаров в этой категории',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final title = data['title']?.toString() ?? 'Без названия';
                    final retailPrice = (data['retailPrice'] as num?)?.toDouble() ?? 0.0;
                    final margin = (data['margin'] as num?)?.toDouble() ?? 0.0;
                    final status = data['status']?.toString() ?? 'pending';
                    final coverUrl = data['coverUrl']?.toString() ?? '';
                    final rejectionReason = data['rejectionReason']?.toString() ?? '';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                    return Material(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showProductDetail(context, doc.id, data),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: coverUrl.isNotEmpty
                                    ? Image.network(coverUrl, width: 60, height: 60, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _PlaceholderImage())
                                    : _PlaceholderImage(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('${retailPrice.toStringAsFixed(0)} ₸', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Text('маржа: ${margin.toStringAsFixed(0)} ₸', style: TextStyle(color: Colors.green.shade700, fontSize: 11)),
                                      ],
                                    ),
                                    if (createdAt != null)
                                      Text('${createdAt.day}.${createdAt.month}.${createdAt.year}', style: TextStyle(color: AppTheme.textDisabled, fontSize: 11)),
                                    if (rejectionReason.isNotEmpty)
                                      Text('Причина: $rejectionReason', style: const TextStyle(color: Colors.red, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (status == 'pending')
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _approveProduct(doc.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.check, color: Colors.green, size: 20),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _rejectProduct(context, doc.id, title),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.close, color: Colors.red, size: 20),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Icon(Icons.chevron_right, color: AppTheme.textDisabled, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, height: 60,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PriceCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
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
