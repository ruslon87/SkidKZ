// lib/features/buyer/screens/buyer_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerCatalogScreen extends StatefulWidget {
  const BuyerCatalogScreen({super.key});

  @override
  State<BuyerCatalogScreen> createState() => _BuyerCatalogScreenState();
}

class _BuyerCatalogScreenState extends State<BuyerCatalogScreen> {
  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _handleBack() async {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    router.go('/buyer/home');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBack();
      },
      child: RefreshIndicator(
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
      ),
    );
  }
}
