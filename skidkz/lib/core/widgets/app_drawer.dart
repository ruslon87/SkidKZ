// lib/core/widgets/app_drawer.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/theme/app_theme.dart';

class AppDrawerItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const AppDrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

class AppDrawer extends StatelessWidget {
  final String headerTitle;
  final String? headerSubtitle;

  final List<AppDrawerItem> items;
  final List<AppDrawerItem>? bottomItems;

  const AppDrawer({
    super.key,
    required this.headerTitle,
    this.headerSubtitle,
    required this.items,
    this.bottomItems,
  });

  String _safeLocation(BuildContext context) {
    final r = GoRouter.maybeOf(context);
    if (r == null) return '';
    return r.routeInformationProvider.value.uri.toString();
  }

  bool _isSelected(BuildContext context, AppDrawerItem item) {
    // лёгкая эвристика: если в onTap внутри go('/path'), то мы не узнаем путь.
    // Поэтому подсветка работает по "приближению": совпадение по title/роуту не делаем.
    // Чтобы подсветка была 100%, можно расширить AppDrawerItem полем route.
    // Сейчас подсветим только по текущему location и некоторым ключевым словам.
    final loc = _safeLocation(context);

    final t = item.title.toLowerCase();
    if (t.contains('глав') && loc.contains('/home')) return true;
    if (t.contains('катал') && loc.contains('/catalog')) return true;
    if (t.contains('избран') && loc.contains('/favorites')) return true;
    if (t.contains('корз') && loc.contains('/cart')) return true;
    if (t.contains('проф') && loc.contains('/profile')) return true;
    if (t.contains('заказ') && loc.contains('/orders')) return true;

    if (t.contains('модерац') && loc.contains('/admin/moderation')) return true;
    if (t.contains('пользов') && loc.contains('/admin/users')) return true;
    if (t.contains('финанс') && loc.contains('/admin/finance')) return true;

    if (t.contains('товар') && loc.contains('/seller/products')) return true;
    if (t.contains('сделк') && loc.contains('/wanghong/deals')) return true;
    if (t.contains('кошел') && loc.contains('/wanghong/wallet')) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = bottomItems ?? const <AppDrawerItem>[];

    return Drawer(
      width: 320,
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: _GlassPanel(
            child: Column(
              children: [
                _Header(
                  title: headerTitle,
                  subtitle: headerSubtitle,
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _SectionLabel('Навигация'),
                      const SizedBox(height: 6),
                      ...items.map((i) => _DrawerTile(
                            icon: i.icon,
                            title: i.title,
                            subtitle: i.subtitle,
                            selected: _isSelected(context, i),
                            onTap: () {
                              Navigator.of(context).maybePop();
                              i.onTap();
                            },
                          )),
                      if (bottom.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _Divider(),
                        const SizedBox(height: 14),
                        _SectionLabel('Другое'),
                        const SizedBox(height: 6),
                        ...bottom.map((i) => _DrawerTile(
                              icon: i.icon,
                              title: i.title,
                              subtitle: i.subtitle,
                              selected: false,
                              onTap: () {
                                Navigator.of(context).maybePop();
                                i.onTap();
                              },
                            )),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                _FooterHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.r20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            // “стекло” на финтеховом фоне
            color: AppColors.surface.withOpacity(0.78),
            borderRadius: BorderRadius.circular(AppRadii.r20),
            border: Border.all(color: AppColors.border.withOpacity(0.9), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 22,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.accent.withOpacity(0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _Header({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppRadii.r16),
        border: Border.all(color: AppColors.border.withOpacity(0.9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 1),
            ),
            child: const Icon(Icons.layers_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.textMuted.withOpacity(0.85),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.accent.withOpacity(0.10) : Colors.transparent;
    final br = selected ? AppColors.accent.withOpacity(0.28) : AppColors.border.withOpacity(0.7);
    final ic = selected ? AppColors.accent : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.r16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.r16),
            border: Border.all(color: br, width: 1),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface2.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border.withOpacity(0.8), width: 1),
                ),
                child: Icon(icon, color: ic),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? AppColors.accent : AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.border.withOpacity(0.8),
    );
  }
}

class _FooterHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.65),
        borderRadius: BorderRadius.circular(AppRadii.r16),
        border: Border.all(color: AppColors.border.withOpacity(0.8), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Финтех-дизайн: чистый фон, изумрудный акцент, минимум шума.',
              style: TextStyle(
                color: AppColors.textMuted.withOpacity(0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
