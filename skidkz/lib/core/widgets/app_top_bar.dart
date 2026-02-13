// lib/core/widgets/app_top_bar.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenu;
  final List<Widget> actions;
  final Widget? leading;

  const AppTopBar({
    super.key,
    required this.title,
    this.onMenu,
    this.actions = const [],
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.86),
            borderRadius: BorderRadius.circular(AppRadii.r16),
            border: Border.all(color: AppColors.border.withOpacity(0.9), width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 6),
              leading ??
                  IconButton(
                    onPressed: onMenu,
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Menu',
                  ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...actions,
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
