// lib/features/auth/screens/role_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/core/widgets/app_gradient_background.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Выберите роль',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Вы можете переключаться между ролями позже.',
                      style: TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    _RoleCard(
                      title: 'Покупатель',
                      subtitle: 'Витрина, корзина, заказы',
                      icon: Icons.shopping_bag_outlined,
                      onTap: () => context.go('/buyer/home'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      title: 'Продавец',
                      subtitle: 'Товары и заказы магазина',
                      icon: Icons.storefront_outlined,
                      onTap: () => context.go('/seller/products'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      title: 'Ванхун',
                      subtitle: 'Сделки, кошелёк, промо',
                      icon: Icons.local_offer_outlined,
                      onTap: () => context.go('/wanghong/home'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      title: 'Админ',
                      subtitle: 'Модерация, пользователи, финансы',
                      icon: Icons.gavel_outlined,
                      onTap: () => context.go('/admin/moderation'),
                    ),

                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/buyer/home'),
                      child: const Text('Продолжить без выбора'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.r16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.r16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Icon(icon, color: AppColors.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
