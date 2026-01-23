import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/user_model.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  DateTime? _lastBackPressedAt;
  bool _saving = false;

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
                  'Выберите роль для демо',
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

    setState(() => _saving = true);

    try {
      final uid = user.uid;
      final phone = user.phoneNumber ?? '';

      // users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'uid': uid,
          'phoneNumber': phone,
          'role': role.name, // buyer / wanghong / seller / admin
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // После этого router redirect сам утащит пользователя в нужный раздел по роли
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения роли: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
