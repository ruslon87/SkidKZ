import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/router/app_router.dart';
import 'package:skidkz/data/models/user_model.dart';

class SkidDrawer extends ConsumerWidget {
  const SkidDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final fbUser = authAsync.asData?.value;

    final roleAsync = ref.watch(activeRoleProvider);
    final role = roleAsync.asData?.value;

    final isStaffAuthed = fbUser != null;
    final hasRole = role != null;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _Header(
              isStaffAuthed: isStaffAuthed,
              phone: fbUser?.phoneNumber,
              role: role,
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _SectionTitle('Витрина'),
                  _item(
                    context,
                    icon: Icons.storefront_outlined,
                    title: 'Каталог',
                    onTap: () => context.go('/buyer/home'),
                  ),
                  _item(
                    context,
                    icon: Icons.help_outline,
                    title: 'Как это работает',
                    onTap: () => _stub(context),
                  ),
                  _item(
                    context,
                    icon: Icons.support_agent_outlined,
                    title: 'Поддержка',
                    onTap: () => _stub(context),
                  ),

                  const Divider(height: 24),

                  const _SectionTitle('Кабинет'),
                  if (!isStaffAuthed)
                    _item(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Войти как сотрудник',
                      onTap: () => context.go('/login'),
                    )
                  else ...[
                    _item(
                      context,
                      icon: _roleIcon(role),
                      title: hasRole ? 'Кабинет (${_roleLabel(role!)})' : 'Выбор роли',
                      onTap: () {
                        // если роли нет — ведём на выбор роли, иначе в дом роли
                        if (!hasRole) {
                          context.go('/role-select');
                        } else {
                          context.go(_homeForRole(role!));
                        }
                      },
                    ),
                    _item(
                      context,
                      icon: Icons.logout,
                      title: 'Выйти',
                      onTap: () async {
                        Navigator.of(context).pop(); // закрыть drawer
                        await fb.FirebaseAuth.instance.signOut();
                        // после signOut redirect сам уведёт в публичную витрину
                        if (context.mounted) context.go('/buyer/home');
                      },
                    ),
                  ],

                  const Divider(height: 24),

                  const _SectionTitle('Юридическое'),
                  _item(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Оферта',
                    onTap: () => _stub(context),
                  ),
                  _item(
                    context,
                    icon: Icons.info_outline,
                    title: 'О приложении',
                    onTap: () => _stub(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop(); // закрыть Drawer
        onTap();
      },
    );
  }

  static void _stub(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Заглушка (MVP)')));
  }

  static IconData _roleIcon(UserRole? role) {
    switch (role) {
      case UserRole.wanghong:
        return Icons.campaign_outlined;
      case UserRole.seller:
        return Icons.storefront_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.buyer:
        return Icons.person_outline;
      default:
        return Icons.badge_outlined;
    }
  }

  static String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.wanghong:
        return 'Ванхун';
      case UserRole.seller:
        return 'Продавец';
      case UserRole.admin:
        return 'Админ';
      case UserRole.buyer:
        return 'Покупатель';
    }
  }

  static String _homeForRole(UserRole role) {
    switch (role) {
      case UserRole.wanghong:
        return '/wanghong/home';
      case UserRole.seller:
        return '/seller/products';
      case UserRole.admin:
        return '/admin/moderation';
      case UserRole.buyer:
        return '/buyer/home';
    }
  }
}

class _Header extends StatelessWidget {
  final bool isStaffAuthed;
  final String? phone;
  final UserRole? role;

  const _Header({
    required this.isStaffAuthed,
    required this.phone,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final title = isStaffAuthed ? 'Сотрудник' : 'Гость';
    final subtitle = isStaffAuthed
        ? '${phone ?? ''}${role != null ? ' • ${_roleLabel(role!)}' : ''}'
        : 'Просмотр витрины без входа';

    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(
            'SkidKZ by Ruslan Sabirov',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  static String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.wanghong:
        return 'Ванхун';
      case UserRole.seller:
        return 'Продавец';
      case UserRole.admin:
        return 'Админ';
      case UserRole.buyer:
        return 'Покупатель';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
      ),
    );
  }
}
