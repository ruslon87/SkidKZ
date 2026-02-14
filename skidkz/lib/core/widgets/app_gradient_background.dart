// lib/core/widgets/app_gradient_background.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bg,
            AppColors.bg2,
          ],
        ),
      ),
      child: Stack(
        children: [
          // лёгкая виньетка сверху
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // очень мягкое изумрудное "свечение" в углу (почти незаметно, но богато)
          Positioned(
            top: -160,
            right: -140,
            child: IgnorePointer(
              child: Container(
                height: 320,
                width: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.05),
                ),
              ),
            ),
          ),

          child,
        ],
      ),
    );
  }
}
