// lib/features/buyer/screens/buyer_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerShell extends StatelessWidget {
  const BuyerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkidKZ'),
        actions: [
          TextButton(
            onPressed: () => context.go('/cabinet'),
            child: const Text('Кабинет'),
          ),
        ],
      ),
      body: child,
    );
  }
}
