// lib/core/widgets/app_gradient_background.dart
import 'package:flutter/material.dart';

/// Единый градиентный фон приложения (как в header Drawer).
/// Используй как обёртку над Scaffold либо над body.
class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, this.child});

  final Widget? child;

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF202625),
      Color(0xFF1A1F1E),
      Color(0xFF121817),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
