// lib/features/info/screens/seller_info_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SellerInfoScreen extends StatelessWidget {
  const SellerInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кабинет магазина')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Откройте магазин и продавайте товары через SkidKZ.',
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
                onPressed: () => context.push('/login?next=%2Fseller%2Fproducts'),
                child: const Text('Войти и продолжить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
