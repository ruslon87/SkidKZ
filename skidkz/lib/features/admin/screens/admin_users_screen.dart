// lib/features/admin/screens/admin_users_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/user_model.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _filter = 'all';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.buyer: return 'Покупатель';
      case UserRole.seller: return 'Продавец';
      case UserRole.wanghong: return 'Партнёр';
      case UserRole.admin: return 'Админ';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.buyer: return Colors.blue;
      case UserRole.seller: return Colors.orange;
      case UserRole.wanghong: return Colors.purple;
      case UserRole.admin: return Colors.red;
    }
  }

  Future<void> _changeRole(BuildContext context, String uid, UserRole currentRole) async {
    final roles = [UserRole.buyer, UserRole.seller, UserRole.wanghong, UserRole.admin];
    final selected = await showDialog<UserRole>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить роль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((r) => ListTile(
            title: Text(_roleLabel(r)),
            leading: Radio<UserRole>(
              value: r,
              groupValue: currentRole,
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        ],
      ),
    );
    if (selected != null && selected != currentRole) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': selected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Роль изменена на ${_roleLabel(selected)}'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Поиск по имени или телефону...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.divider)),
              ),
            ),
          ),
          // Фильтры по роли
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _RoleChip(label: 'Все', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _RoleChip(label: 'Покупатели', selected: _filter == 'buyer', onTap: () => setState(() => _filter = 'buyer')),
                const SizedBox(width: 8),
                _RoleChip(label: 'Продавцы', selected: _filter == 'seller', onTap: () => setState(() => _filter = 'seller')),
                const SizedBox(width: 8),
                _RoleChip(label: 'Партнёры', selected: _filter == 'wanghong', onTap: () => setState(() => _filter = 'wanghong')),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snap.data!.docs;
                if (_filter != 'all') {
                  docs = docs.where((d) => (d.data()['role'] as String?) == _filter).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data();
                    final name = ((data['name'] as String?) ?? '').toLowerCase();
                    final phone = ((data['phone'] as String?) ?? '').toLowerCase();
                    return name.contains(_searchQuery) || phone.contains(_searchQuery);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(child: Text('Пользователей нет', style: TextStyle(color: AppTheme.textSecondary)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final uid = docs[i].id;
                    final name = (data['name'] as String?) ?? 'Без имени';
                    final phone = (data['phone'] as String?) ?? '—';
                    final roleStr = (data['role'] as String?) ?? 'buyer';
                    final role = UserRole.values.firstWhere((r) => r.name == roleStr, orElse: () => UserRole.buyer);
                    final promoCode = data['promoCode'] as String?;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppTheme.divider),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(phone, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            if (promoCode != null)
                              Text('Промокод: $promoCode', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        trailing: GestureDetector(
                          onTap: () => _changeRole(context, uid, role),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _roleColor(role).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _roleColor(role).withValues(alpha: 0.3)),
                            ),
                            child: Text(_roleLabel(role),
                                style: TextStyle(color: _roleColor(role), fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        isThreeLine: promoCode != null,
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.selected, required this.onTap});

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
            style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}
