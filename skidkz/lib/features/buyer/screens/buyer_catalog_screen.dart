// lib/features/buyer/screens/buyer_catalog_screen.dart

import 'package:flutter/material.dart';

class BuyerCatalogScreen extends StatelessWidget {
  const BuyerCatalogScreen({super.key});

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
            'Каталог',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text('Заглушка. Здесь будет каталог с фильтрами/категориями.'),
        ],
      ),
    );
  }
}
