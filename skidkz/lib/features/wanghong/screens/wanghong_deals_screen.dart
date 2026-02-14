// lib/features/wanghong/screens/wanghong_deals_screen.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class WanghongDealsScreen extends StatelessWidget {
  const WanghongDealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Text(
          'Сделки',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
