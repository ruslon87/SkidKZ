// lib/features/info/screens/wanghong_info_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WanghongInfoScreen extends StatelessWidget {
  const WanghongInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кабинет ванхуна')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Зарабатывайте на промокодах и рекомендациях.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Здесь будет описание условий и шагов подключения.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/login?next=%2Fwanghong%2Fhome'),
                child: const Text('Войти и продолжить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
