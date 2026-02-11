// lib/features/buyer/screens/buyer_profile_screen.dart

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({super.key});

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    final user = fb.FirebaseAuth.instance.currentUser;

    // Профиль открыт гостю, но показываем CTA
    if (user == null) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Профиль',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Войдите, чтобы видеть профиль, заказы и управлять настройками.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/login?next=%2Fbuyer%2Fprofile'),
                child: const Text('Войти / зарегистрироваться'),
              ),
            ),
          ],
        ),
      );
    }

    // Авторизован
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Профиль',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text('UID: ${user.uid}'),
          const SizedBox(height: 6),
          Text('Телефон: ${user.phoneNumber ?? '-'}'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await fb.FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go('/buyer/home');
                }
              },
              child: const Text('Выйти'),
            ),
          ),
        ],
      ),
    );
  }
}
