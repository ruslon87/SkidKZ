// lib/features/auth/screens/role_selection_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/user_model.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  DateTime? _lastBackPressedAt;
  bool _saving = false;

  // whitelist админов (лучше UID)
  static const Set<String> _adminUids = {
    // 'YOUR_ADMIN_UID_HERE',
  };

  // временно можно whitelist по телефону (хуже)
  static const Set<String> _adminPhones = {
    // '+7700XXXXXXX',
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final now = DateTime.now();
        final last = _lastBackPressedAt;

        if (last == null || now.difference(last) > const Duration(seconds: 2)) {
          _lastBackPressedAt = now;

          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text('Нажмите ещё раз для выхода'),
                duration: Duration(seconds: 2),
              ),
            );
          return;
        }

        await SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(40),
                Text(
                  'SkidKZ',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const Gap(8),
                Text(
                  'Выберите роль для кабинета',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const Gap(40),

                Expanded(
                  child: IgnorePointer(
                    ignoring: _saving,
                    child: Opacity(
                      opacity: _saving ? 0.6 : 1,
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _RoleCard(
                            title: 'Покупатель',
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.blue,
                            onTap: () => _selectRole(UserRole.buyer),
                          ),
                          _RoleCard(
                            title: 'Ванхун',
                            icon: Icons.campaign_outlined,
                            color: Colors.purple,
                            onTap: () => _selectRole(UserRole.wanghong),
                          ),
                          _RoleCard(
                            title: 'Продавец',
                            icon: Icons.storefront_outlined,
                            color: Colors.orange,
                            onTap: () => _selectRole(UserRole.seller),
                          ),
                          _RoleCard(
                            title: 'Админ',
                            icon: Icons.admin_panel_settings_outlined,
                            color: Colors.red,
                            onTap: () => _selectRole(UserRole.admin),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_saving) ...[
                  const Gap(12),
                  const Center(child: CircularProgressIndicator()),
                ],

                const Gap(16),
                Text(
                  'SkidKZ by Ruslan Sabirov',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectRole(UserRole role) async {
    if (_saving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала войдите по SMS')),
      );
      return;
    }

    // Админ — только whitelist
    if (role == UserRole.admin) {
      final uidOk = _adminUids.contains(user.uid);
      final phoneOk =
          user.phoneNumber != null && _adminPhones.contains(user.phoneNumber);
      if (!uidOk && !phoneOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Доступ администратора запрещён (Whitelist).')),
        );
        return;
      }
    }

    // Собираем данные роли (анкета/поля роли)
    final profileData = await _collectRoleData(role);
    if (!mounted) return;
    if (profileData == null) return; // отмена

    setState(() => _saving = true);

    try {
      final uid = user.uid;
      final phone = user.phoneNumber ?? '';

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userRef.get();

      final existing = snap.data() ?? <String, dynamic>{};

      // Берём существующие roles + гарантируем buyer (потому что покупательская зона всегда нужна)
      final existingRolesRaw = existing['roles'];
      final existingLegacyRole = existing['role'] as String?;
      final mergedRoles = <String>{
        'buyer',
        ..._rolesFromAny(existingRolesRaw, existingLegacyRole),
        role.name,
      }.toList()
        ..sort();

      // Гарантируем profiles map
      final existingProfiles =
          (existing['profiles'] is Map<String, dynamic>)
              ? Map<String, dynamic>.from(existing['profiles'])
              : <String, dynamic>{};

      existingProfiles[role.name] = {
        ...(existingProfiles[role.name] is Map
            ? Map<String, dynamic>.from(existingProfiles[role.name])
            : <String, dynamic>{}),
        ...profileData,
      };

      await userRef.set(
        {
          'uid': uid,

          // ✅ пишем оба, чтобы не было рассинхрона
          'phone': phone,
          'phoneNumber': phone,

          // ✅ роли и активная роль
          'roles': mergedRoles,
          'activeRole': role.name,

          // ✅ оставим legacy "role" как fallback (можно убрать позже)
          'role': role.name,

          // ✅ единый канон: profiles
          'profiles': existingProfiles,

          'createdAt': existing['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения роли: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  // Возвращает список ролей строками из raw roles / legacy role
  List<String> _rolesFromAny(dynamic rawRoles, String? rawRoleLegacy) {
    if (rawRoles is List) {
      final out = <String>[];
      for (final x in rawRoles) {
        if (x is String && x.trim().isNotEmpty) out.add(x.trim());
      }
      if (out.isNotEmpty) return out.toSet().toList();
    }

    if (rawRoleLegacy != null && rawRoleLegacy.trim().isNotEmpty) {
      return [rawRoleLegacy.trim()];
    }

    return [];
  }

  Future<Map<String, dynamic>?> _collectRoleData(UserRole role) async {
    switch (role) {
      case UserRole.buyer:
        // Минимум для MVP: отметка, что можно продолжать.
        // Поля BuyerProfile в модели имеют дефолты, так что map может быть минимальным.
        return {
          'completed': false,
          'acceptedTerms': true,
          'updatedAt': DateTime.now().toIso8601String(),
        };

      case UserRole.wanghong:
        return _showWanghongDialog();

      case UserRole.seller:
        return _showSellerDialog();

      case UserRole.admin:
        return {'completed': true, 'isWhitelistedAdmin': true};
    }
  }

  Future<Map<String, dynamic>?> _showWanghongDialog() async {
    final kaspiController = TextEditingController();
    bool accepted = false;
    String? errorText;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Ванхун — данные для выплат'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: kaspiController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Kaspi номер (обязательно)',
                      hintText: 'Например: +7 700 123 45 67',
                      errorText: errorText,
                    ),
                  ),
                  const Gap(12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: accepted,
                        onChanged: (v) => setSt(() => accepted = v ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSt(() => accepted = !accepted),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text('Я принимаю оферту (обязательно)'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!accepted)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Без акцепта оферты регистрация недоступна.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final kaspi = kaspiController.text.trim();
                    if (kaspi.isEmpty) {
                      setSt(() => errorText = 'Введите Kaspi номер');
                      return;
                    }
                    if (!accepted) {
                      setSt(() => errorText = 'Нужно принять оферту');
                      return;
                    }

                    Navigator.pop(ctx, {
                      'completed': false,
                      'kaspiNumber': kaspi,
                      'offerAccepted': true,
                      'offerAcceptedAt': DateTime.now().toIso8601String(),
                      'status': 'pending', // pending/approved/rejected
                      'wallet': {
                        'balance': 0.0,
                        'hold': 0.0,
                        'minRemaining': 1000.0,
                        'holdDays': 14,
                      },
                    });
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    kaspiController.dispose();
    return result;
  }

  Future<Map<String, dynamic>?> _showSellerDialog() async {
    final storeController = TextEditingController();
    bool accepted = false;
    bool isService = false;
    String? errorText;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Продавец — данные'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: storeController,
                    decoration: InputDecoration(
                      labelText: 'Название продавца',
                      hintText: 'Например: Шинный Центр Алматы',
                      errorText: errorText,
                    ),
                  ),
                  const Gap(12),
                  SwitchListTile(
                    value: isService,
                    onChanged: (v) => setSt(() => isService = v),
                    title: Text(isService ? 'Тип: Услуги' : 'Тип: Товары'),
                    subtitle: const Text('Нужно для логики оплат (товар/услуга).'),
                  ),
                  const Gap(12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: accepted,
                        onChanged: (v) => setSt(() => accepted = v ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSt(() => accepted = !accepted),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text('Я принимаю оферту (обязательно)'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final storeName = storeController.text.trim();
                    if (storeName.isEmpty) {
                      setSt(() => errorText = 'Введите название продавца');
                      return;
                    }
                    if (!accepted) {
                      setSt(() => errorText = 'Нужно принять оферту');
                      return;
                    }

                    Navigator.pop(ctx, {
                      'completed': false,
                      'storeName': storeName,
                      'isServiceSeller': isService,
                      'offerAccepted': true,
                      'offerAcceptedAt': DateTime.now().toIso8601String(),
                      'status': 'pending', // pending/approved/rejected
                    });
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    storeController.dispose();
    return result;
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const Gap(16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
