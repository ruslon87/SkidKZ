import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/user_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(40),
              Text(
                'Welcome to SkidKZ',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                'Select a demo role to proceed',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _RoleCard(
                      title: 'Buyer',
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.blue,
                      onTap: () => _login(ref, UserRole.buyer),
                    ),
                    _RoleCard(
                      title: 'Wanghong',
                      icon: Icons.campaign_outlined,
                      color: Colors.purple,
                      onTap: () => _login(ref, UserRole.wanghong),
                    ),
                    _RoleCard(
                      title: 'Seller',
                      icon: Icons.storefront_outlined,
                      color: Colors.orange,
                      onTap: () => _login(ref, UserRole.seller),
                    ),
                    _RoleCard(
                      title: 'Admin',
                      icon: Icons.admin_panel_settings_outlined,
                      color: Colors.red,
                      onTap: () => _login(ref, UserRole.admin),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => context.push('/login'), 
                child: const Text('Simulate Phone Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login(WidgetRef ref, UserRole role) {
    ref.read(authProvider.notifier).login(role);
    // Router redirect will handle navigation
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
