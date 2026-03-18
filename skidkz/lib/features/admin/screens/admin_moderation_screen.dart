// lib/features/admin/screens/admin_moderation_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  String _filter = 'all';

  Future<void> _setStatus(String productId, String status) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'active' ? 'Товар опубликован' : 'Товар снят с публикации'),
          backgroundColor: status == 'active' ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Модерация товаров'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _Chip(label: 'Все', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _Chip(label: 'Активные', selected: _filter == 'active', onTap: () => setState(() => _filter = 'active')),
                const SizedBox(width: 8),
                _Chip(label: 'Черновики', selected: _filter == 'draft', onTap: () => setState(() => _filter = 'draft')),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('products').orderBy('updatedAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snap.data!.docs;
                if (_filter != 'all') {
                  docs = docs.where((d) => (d.data()['status'] as String?) == _filter).toList();
                }
                if (docs.isEmpty) {
                  return Center(child: Text('Товаров нет', style: TextStyle(color: AppTheme.textSecondary)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final id = docs[i].id;
                    final title = (data['title'] as String?) ?? 'Без названия';
                    final price = (data['retailPrice'] as int?) ?? 0;
                    final margin = (data['margin'] as int?) ?? 0;
                    final status = (data['status'] as String?) ?? 'draft';
                    final coverUrl = data['coverUrl'] as String?;
                    final isActive = status == 'active';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppTheme.divider),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: AppTheme.elevated,
                                child: coverUrl != null && coverUrl.isNotEmpty
                                    ? Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: AppTheme.textDisabled))
                                    : Icon(Icons.image_outlined, color: AppTheme.textDisabled),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('${formatter.format(price)} · Маржа: ${formatter.format(margin)}',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(isActive ? 'Активен' : 'Черновик',
                                      style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _setStatus(id, isActive ? 'draft' : 'active'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(isActive ? 'Снять' : 'Опубл.',
                                        style: TextStyle(color: isActive ? Colors.red : Colors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}
