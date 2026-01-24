import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/router/app_router.dart';
import 'package:skidkz/features/common/widgets/skid_drawer.dart';

class BuyerShell extends ConsumerWidget {
  const BuyerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final fbUser = authAsync.asData?.value;

    final roleAsync = ref.watch(activeRoleProvider);
    final role = roleAsync.asData?.value;

    return Scaffold(
      drawer: const SkidDrawer(),
      appBar: AppBar(
        title: const Text('SkidKZ'),
        actions: [
          // Правая кнопка зависит от статуса:
          // - если не авторизован (staff) -> Войти
          // - если авторизован и роль есть -> Кабинет
          // - если авторизован но роли нет -> Роль
          TextButton(
            onPressed: () {
              if (fbUser == null) {
                context.go('/login');
                return;
              }
              if (role == null) {
                context.go('/role-select');
                return;
              }
              context.go('/cabinet');
            },
            child: Text(
              fbUser == null ? 'Войти' : (role == null ? 'Роль' : 'Кабинет'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: child,
    );
  }
}
