// lib/features/common/widgets/skid_drawer.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SkidDrawer extends StatelessWidget {
  const SkidDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // router может быть временно недоступен (особенно на старте/перестройке дерева)
    final router = GoRouter.maybeOf(context);

    void closeDrawer() {
      Navigator.of(context).pop();
    }

    void go(String path) {
      closeDrawer();
      router?.go(path);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'SkidKZ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text('Меню'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Витрина'),
              onTap: () => go('/buyer/home'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Кабинет сотрудника'),
              subtitle: Text(user == null ? 'Войти' : 'Открыть'),
              onTap: () => go('/cabinet'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                user == null
                    ? 'Вы не авторизованы'
                    : 'UID: ${user.uid}\n${user.phoneNumber ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
