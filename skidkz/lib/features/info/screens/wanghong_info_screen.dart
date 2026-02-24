import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WanghongInfoScreen extends StatelessWidget {
  const WanghongInfoScreen({super.key});

  void _safePush(BuildContext context, String path) {
    final r = GoRouter.maybeOf(context);
    if (r == null) return;
    r.push(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Инфо для ванхуна')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Описание условий для ванхунов (заглушка).'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _safePush(
                  context,
                  '/login?next=%2Fwanghong%2Fhome',
                ),
                child: const Text('Войти и продолжить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
