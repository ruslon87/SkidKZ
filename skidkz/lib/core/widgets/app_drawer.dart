// lib/core/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AppDrawerItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const AppDrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class AppDrawer extends StatelessWidget {
  final String headerTitle;
  final String? headerSubtitle;
  final List<AppDrawerItem> items;
  final List<AppDrawerItem> bottomItems;

  const AppDrawer({
    super.key,
    required this.headerTitle,
    this.headerSubtitle,
    required this.items,
    this.bottomItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppRadii.r16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    if (headerSubtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        headerSubtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...items.map((e) => _tile(context, e)),
                ],
              ),
            ),
            if (bottomItems.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: bottomItems.map((e) => _tile(context, e)).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, AppDrawerItem item) {
    return ListTile(
      leading: Icon(item.icon, color: AppColors.text),
      title: Text(
        item.title,
        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Navigator.of(context).maybePop(); // закрыть drawer
        item.onTap();
      },
    );
  }
}
