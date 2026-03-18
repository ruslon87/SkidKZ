// lib/features/admin/screens/admin_users_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _filter = 'all';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _allRoles = ['buyer', 'seller', 'wanghong', 'admin'];

  String _roleLabel(String role) {
    switch (role) {
      case 'buyer': return 'Покупатель';
      case 'seller': return 'Продавец';
      case 'wanghong': return 'Партнёр';
      case 'admin': return 'Администратор';
      default: return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'buyer': return Colors.blue;
      case 'seller': return Colors.orange;
      case 'wanghong': return Colors.purple;
      case 'admin': return Colors.red;
      default: return Colors.grey;
    }
  }

  List<String> _rolesFromDoc(Map<String, dynamic> data) {
    final raw = data['roles'];
    if (raw is List && raw.isNotEmpty) {
      return raw.whereType<String>().toList();
    }
    final single = data['role'] as String?;
    return [single ?? 'buyer'];
  }

  Future<void> _manageRoles(BuildContext context, String uid, List<String> currentRoles) async {
    final selected = List<String>.from(currentRoles);
    final confirmed = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Управление ролями'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _allRoles.map((r) => CheckboxListTile(
              value: selected.contains(r),
              title: Text(_roleLabel(r)),
              activeColor: _roleColor(r),
              onChanged: (v) {
                setS(() {
                  if (v == true) {
                    if (!selected.contains(r)) selected.add(r);
                  } else {
                    if (selected.length > 1) selected.remove(r);
                  }
                });
              },
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'roles': confirmed,
        'role': confirmed.first,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Роли обновлены: ${confirmed.map(_roleLabel).join(', ')}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleBlock(BuildContext context, String uid, bool isBlocked) async {
    final action = isBlocked ? 'разблокировать' : 'заблокировать';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBlocked ? 'Разблокировать?' : 'Заблокировать?'),
        content: Text('Вы уверены, что хотите $action этого пользователя?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBlocked ? 'Разблокировать' : 'Заблокировать'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isBlocked': !isBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBlocked ? 'Пользователь разблокирован' : 'Пользователь заблокирован'),
            backgroundColor: isBlocked ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUserDetail(BuildContext context, String uid, Map<String, dynamic> data) {
    final roles = _rolesFromDoc(data);
    final phone = data['phone']?.toString() ?? data['phoneNumber']?.toString() ?? '-';
    final isBlocked = data['isBlocked'] == true;
    final profilesRaw = data['profiles'];
    final profiles = (profilesRaw is Map) ? profilesRaw.cast<String, dynamic>() : <String, dynamic>{};
    final buyerRaw = profiles['buyer'];
    final buyer = (buyerRaw is Map) ? buyerRaw.cast<String, dynamic>() : <String, dynamic>{};
    final wanghongRaw = profiles['wanghong'];
    final wanghong = (wanghongRaw is Map) ? wanghongRaw.cast<String, dynamic>() : <String, dynamic>{};
    final sellerRaw = profiles['seller'];
    final seller = (sellerRaw is Map) ? sellerRaw.cast<String, dynamic>() : <String, dynamic>{};
    final firstName = buyer['firstName']?.toString() ?? '';
    final lastName = buyer['lastName']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final city = buyer['city']?.toString() ?? '';
    final kaspiPhone = buyer['kaspiPhone']?.toString() ?? wanghong['kaspiPhone']?.toString() ?? '';
    final promoCode = wanghong['promoCode']?.toString() ?? '';
    final totalEarnings = (wanghong['totalEarnings'] as num?)?.toDouble() ?? 0.0;
    final pendingBalance = (wanghong['pendingBalance'] as num?)?.toDouble() ?? 0.0;
    final storeName = seller['storeName']?.toString() ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : (phone.isNotEmpty ? phone[phone.length - 1] : '?'),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : 'Пользователь',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(phone, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        if (isBlocked)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: const Text('ЗАБЛОКИРОВАН', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailSection(
                title: 'Роли',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: roles.map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _roleColor(r).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _roleColor(r).withOpacity(0.3)),
                    ),
                    child: Text(_roleLabel(r), style: TextStyle(color: _roleColor(r), fontWeight: FontWeight.w600, fontSize: 12)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _DetailSection(
                title: 'Личные данные',
                child: Column(
                  children: [
                    _DetailRow(label: 'UID', value: uid, canCopy: true),
                    _DetailRow(label: 'Телефон', value: phone),
                    if (fullName.isNotEmpty) _DetailRow(label: 'Имя', value: fullName),
                    if (city.isNotEmpty) _DetailRow(label: 'Город', value: city),
                    if (kaspiPhone.isNotEmpty) _DetailRow(label: 'Kaspi', value: kaspiPhone),
                    if (createdAt != null) _DetailRow(label: 'Регистрация', value: '${createdAt.day}.${createdAt.month}.${createdAt.year}'),
                  ],
                ),
              ),
              if (roles.contains('wanghong')) ...[
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Данные партнёра',
                  child: Column(
                    children: [
                      if (promoCode.isNotEmpty) _DetailRow(label: 'Промокод', value: promoCode, canCopy: true),
                      _DetailRow(label: 'Заработано', value: '${totalEarnings.toStringAsFixed(0)} ₸'),
                      _DetailRow(label: 'К выплате', value: '${pendingBalance.toStringAsFixed(0)} ₸'),
                    ],
                  ),
                ),
              ],
              if (roles.contains('seller') && storeName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Данные продавца',
                  child: Column(
                    children: [
                      _DetailRow(label: 'Магазин', value: storeName),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _manageRoles(context, uid, roles);
                },
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Управление ролями'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _toggleBlock(context, uid, isBlocked);
                },
                icon: Icon(isBlocked ? Icons.lock_open_outlined : Icons.block_outlined),
                label: Text(isBlocked ? 'Разблокировать' : 'Заблокировать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocked ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
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
        title: const Text('Пользователи'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _RoleChip(label: 'Все', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _RoleChip(label: 'Покупатели', selected: _filter == 'buyer', color: Colors.blue, onTap: () => setState(() => _filter = 'buyer')),
                const SizedBox(width: 8),
                _RoleChip(label: 'Продавцы', selected: _filter == 'seller', color: Colors.orange, onTap: () => setState(() => _filter = 'seller')),
                const SizedBox(width: 8),
                _RoleChip(label: 'Партнёры', selected: _filter == 'wanghong', color: Colors.purple, onTap: () => setState(() => _filter = 'wanghong')),
                const SizedBox(width: 8),
                _RoleChip(label: 'Заблокированные', selected: _filter == 'blocked', color: Colors.red, onTap: () => setState(() => _filter = 'blocked')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Ошибка: ${snap.error}'));
                }
                var docs = snap.data?.docs ?? [];
                if (_filter == 'blocked') {
                  docs = docs.where((d) => d.data()['isBlocked'] == true).toList();
                } else if (_filter != 'all') {
                  docs = docs.where((d) {
                    final roles = _rolesFromDoc(d.data());
                    return roles.contains(_filter);
                  }).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data();
                    final phone = (data['phone']?.toString() ?? '').toLowerCase();
                    final profilesRaw = data['profiles'];
                    final profiles = (profilesRaw is Map) ? profilesRaw.cast<String, dynamic>() : <String, dynamic>{};
                    final buyerRaw = profiles['buyer'];
                    final buyer = (buyerRaw is Map) ? buyerRaw.cast<String, dynamic>() : <String, dynamic>{};
                    final firstName = (buyer['firstName']?.toString() ?? '').toLowerCase();
                    final lastName = (buyer['lastName']?.toString() ?? '').toLowerCase();
                    return phone.contains(_searchQuery) || firstName.contains(_searchQuery) || lastName.contains(_searchQuery);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Пользователи не найдены', style: TextStyle(color: AppTheme.textSecondary)),
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
                    final uid = data['uid']?.toString() ?? doc.id;
                    final phone = data['phone']?.toString() ?? data['phoneNumber']?.toString() ?? '-';
                    final roles = _rolesFromDoc(data);
                    final isBlocked = data['isBlocked'] == true;
                    final profilesRaw = data['profiles'];
                    final profiles = (profilesRaw is Map) ? profilesRaw.cast<String, dynamic>() : <String, dynamic>{};
                    final buyerRaw = profiles['buyer'];
                    final buyer = (buyerRaw is Map) ? buyerRaw.cast<String, dynamic>() : <String, dynamic>{};
                    final firstName = buyer['firstName']?.toString() ?? '';
                    final lastName = buyer['lastName']?.toString() ?? '';
                    final fullName = '$firstName $lastName'.trim();
                    final wanghongRaw = profiles['wanghong'];
                    final wanghong = (wanghongRaw is Map) ? wanghongRaw.cast<String, dynamic>() : <String, dynamic>{};
                    final promoCode = wanghong['promoCode']?.toString() ?? '';

                    return Material(
                      color: isBlocked ? Colors.red.shade50 : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showUserDetail(context, uid, data),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isBlocked ? Colors.red.shade200 : AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isBlocked ? Colors.red.shade100 : AppTheme.primary.withOpacity(0.1),
                                child: isBlocked
                                    ? const Icon(Icons.block, color: Colors.red, size: 18)
                                    : Text(
                                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName.isNotEmpty ? fullName : phone,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    if (fullName.isNotEmpty)
                                      Text(phone, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                    if (promoCode.isNotEmpty)
                                      Text('Промокод: $promoCode', style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      children: roles.map((r) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _roleColor(r).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(_roleLabel(r), style: TextStyle(color: _roleColor(r), fontSize: 10, fontWeight: FontWeight.w600)),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
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
  final Color? color;

  const _RoleChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppTheme.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;
  const _DetailRow({required this.label, required this.value, this.canCopy = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          if (canCopy)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скопировано'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                );
              },
              child: Icon(Icons.copy_outlined, size: 16, color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}
