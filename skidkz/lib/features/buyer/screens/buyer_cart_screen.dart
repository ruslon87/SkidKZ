// lib/features/buyer/screens/buyer_cart_screen.dart

import 'package:flutter/material.dart';

class BuyerCartScreen extends StatelessWidget {
  const BuyerCartScreen({super.key});

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Корзина',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text('Заглушка. Здесь будет корзина пользователя.'),
        ],
      ),
    );
  }
}
