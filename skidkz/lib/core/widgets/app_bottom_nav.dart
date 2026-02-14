// lib/core/widgets/app_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AppNavItem {
  final IconData icon;
  final String label;

  const AppNavItem({required this.icon, required this.label});
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<AppNavItem> items;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // фон и "премиальный" top-glow
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.accent.withOpacity(0.22), // тонкая линия
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.18),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, -6), // свет вверх
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            for (final i in items)
              BottomNavigationBarItem(
                icon: Icon(i.icon),
                label: i.label,
              ),
          ],
        ),
      ),
    );
  }
}
