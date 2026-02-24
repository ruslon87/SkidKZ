import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerOnboardingScreen extends StatelessWidget {
  const BuyerOnboardingScreen({
    super.key,
    this.nextPath,
  });

  final String? nextPath;

  void _safeGo(BuildContext context, String path) {
    final r = GoRouter.maybeOf(context);
    if (r == null) return;
    r.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final next = nextPath?.trim();

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
                  if (next != null && next.isNotEmpty) {
                    _safeGo(context, next);
                  } else {
                    _safeGo(context, '/buyer/home');
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
