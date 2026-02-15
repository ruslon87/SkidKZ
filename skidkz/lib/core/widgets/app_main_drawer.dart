// lib/core/widgets/app_main_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/location/location_controller.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/core/router/app_router.dart'; // тут лежат authStateChangesProvider/currentUserDocProvider
import 'package:skidkz/data/models/user_model.dart';

class AppMainDrawer extends ConsumerWidget {
  const AppMainDrawer({super.key});

  String _roleRu(UserRole role) {
    switch (role) {
      case UserRole.buyer:
        return 'Покупатель';
      case UserRole.seller:
        return 'Магазин';
      case UserRole.wanghong:
        return 'Ванхун';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  void _go(BuildContext context, String path) {
    Navigator.of(context).maybePop();
    context.go(path);
  }

  void _goLoginNext(BuildContext context, String nextPath) {
    // next может содержать /... — передаём как есть, go_router нормально обработает
    _go(context, '/login?next=$nextPath');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final userAsync = ref.watch(currentUserDocProvider);

    final loc = ref.watch(locationControllerProvider);
    final locCtrl = ref.read(locationControllerProvider.notifier);

    final fbUser = authAsync.asData?.value;
    final user = userAsync.asData?.value;

    final bool isAuthed = fbUser != null && user != null;

    final headerTitle = isAuthed
        ? (user!.buyerProfile.fullName.trim().isNotEmpty
            ? user.buyerProfile.fullName.trim()
            : (user.phone ?? 'Пользователь'))
        : 'Войти / Регистрация';

    final headerSubtitle = isAuthed
        ? 'Роль: ${_roleRu(user!.activeRole)}'
        : 'Заказы, избранное, бонусы';

    final cityText = loc.city;
    final cityLoading = loc.isLoading;

    // Права на кабинеты/подключение
    final hasSeller = isAuthed && user!.roles.contains(UserRole.seller);
    final hasWanghong = isAuthed && user!.roles.contains(UserRole.wanghong);
    final hasAdmin = isAuthed && user!.roles.contains(UserRole.admin);

    final sellerReady = isAuthed && user!.sellerProfile.completed;
    final wanghongReady = isAuthed && user!.wanghongProfile.completed;

    final showSellerCabinet = hasSeller && sellerReady;
    final showWanghongCabinet = hasWanghong && wanghongReady;
    final showAdminCabinet = hasAdmin;

    final showOpenSeller = !isAuthed || !showSellerCabinet;
    final showJoinWanghong = !isAuthed || !showWanghongCabinet;

    return Drawer(
      width: 320,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            children: [
              _Header(
                title: headerTitle,
                subtitle: headerSubtitle,
                city: cityText,
                cityLoading: cityLoading,
                onCityTap: () => locCtrl.refresh(),
                onHeaderTap: isAuthed
                    ? null
                    : () => _go(context, '/login'),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Section('Аккаунт'),
                    _Tile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Мои заказы',
                      onTap: () {
                        if (!isAuthed) {
                          _goLoginNext(context, '/buyer/orders');
                          return;
                        }
                        _go(context, '/buyer/orders');
                      },
                    ),

                    const SizedBox(height: 14),
                    _Divider(),

                    // Кабинеты (только подключённые)
                    const SizedBox(height: 14),
                    _Section('Кабинеты'),
                    if (showSellerCabinet)
                      _Tile(
                        icon: Icons.storefront_outlined,
                        title: 'Кабинет магазина',
                        onTap: () => _go(context, '/seller/products'),
                      ),
                    if (showWanghongCabinet)
                      _Tile(
                        icon: Icons.campaign_outlined,
                        title: 'Кабинет ванхуна',
                        onTap: () => _go(context, '/wanghong/home'),
                      ),
                    if (showAdminCabinet)
                      _Tile(
                        icon: Icons.gavel_outlined,
                        title: 'Админка',
                        onTap: () => _go(context, '/admin/moderation'),
                      ),

                    const SizedBox(height: 14),
                    _Divider(),

                    // Для бизнеса (только не подключённые)
                    const SizedBox(height: 14),
                    _Section('Для бизнеса'),
                    if (showOpenSeller)
                      _Tile(
                        icon: Icons.add_business_outlined,
                        title: 'Открыть магазин',
                        onTap: () {
                          if (!isAuthed) {
                            _goLoginNext(context, '/info/seller');
                            return;
                          }
                          _go(context, '/info/seller');
                        },
                      ),
                    if (showJoinWanghong)
                      _Tile(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'Подключиться как ванхун',
                        onTap: () {
                          if (!isAuthed) {
                            _goLoginNext(context, '/info/wanghong');
                            return;
                          }
                          _go(context, '/info/wanghong');
                        },
                      ),

                    const SizedBox(height: 14),
                    _Divider(),

                    const SizedBox(height: 14),
                    _Section('Сервис'),
                    _Tile(
                      icon: Icons.support_agent_outlined,
                      title: 'Поддержка',
                      onTap: () {
                        Navigator.of(context).maybePop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Поддержка: скоро'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final String city;
  final bool cityLoading;
  final VoidCallback onCityTap;
  final VoidCallback? onHeaderTap;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.city,
    required this.cityLoading,
    required this.onCityTap,
    this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.r20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.r16),
              onTap: onHeaderTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.r16),
            onTap: onCityTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.r16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 6),
                  if (cityLoading) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    city,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

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

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.r16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.r16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface2.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.border.withOpacity(0.9), width: 1),
                  ),
                  child: Icon(icon, color: AppColors.textMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 22),
              ],
            ),
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
      color: AppColors.border.withOpacity(0.9),
    );
  }
}
