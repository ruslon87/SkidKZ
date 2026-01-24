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
      final phoneOk = user.phoneNumber != null && _adminPhones.contains(user.phoneNumber);
      if (!uidOk && !phoneOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Доступ администратора запрещён (Whitelist).')),
        );
        return;
      }
    }

    // Собираем данные роли
    final extra = await _collectRoleData(role);
    if (!mounted) return; // диалог мог закрыть экран
    if (extra == null) return; // отмена

    setState(() => _saving = true);

    try {
      final uid = user.uid;
      final phone = user.phoneNumber ?? '';

      // КРИТИЧНО: сохраняем activeRole (и role для совместимости)
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'uid': uid,
          'phoneNumber': phone,

          'activeRole': role.name, // то, что роутер читает
          'role': role.name,       // fallback/совместимость

          'profile': extra,

          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // НИКАКОЙ навигации / snackbar после успешного сохранения.
      // GoRouter сам увезёт пользователя по activeRole.
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

  Future<Map<String, dynamic>?> _collectRoleData(UserRole role) async {
    switch (role) {
      case UserRole.buyer:
        return {'offerAccepted': true};

      case UserRole.wanghong:
        return _showWanghongDialog();

      case UserRole.seller:
        return _showSellerDialog();

      case UserRole.admin:
        return {'isWhitelistedAdmin': true};
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
                      'kaspiNumber': kaspi,
                      'offerAccepted': true,
                      'offerAcceptedAt': DateTime.now().toIso8601String(),
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
