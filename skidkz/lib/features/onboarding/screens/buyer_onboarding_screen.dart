// lib/features/onboarding/screens/buyer_onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerOnboardingScreen extends StatelessWidget {
  const BuyerOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final next = GoRouterState.of(context).uri.queryParameters['next'];

    return Scaffold(
      appBar: AppBar(title: const Text('Онбординг покупателя')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заполним профиль покупателя (упрощённо).',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('Тут будет анкета/галочки/условия.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Заглушка: на реальном онбординге тут будет сохранение профиля.
                  if (next != null && next.trim().isNotEmpty) {
                    context.go(next);
                  } else {
                    context.go('/buyer/home');
                  }
                },
                child: const Text('Готово'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
