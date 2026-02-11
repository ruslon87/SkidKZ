// lib/features/buyer/screens/buyer_favorites_screen.dart

import 'package:flutter/material.dart';

class BuyerFavoritesScreen extends StatelessWidget {
  const BuyerFavoritesScreen({super.key});

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
            'Избранное',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text('Заглушка. Здесь будут избранные товары.'),
        ],
      ),
    );
  }
}
