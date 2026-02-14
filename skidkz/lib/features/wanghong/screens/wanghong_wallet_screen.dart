// lib/features/wanghong/screens/wanghong_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class WanghongWalletScreen extends StatelessWidget {
  const WanghongWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Text(
              'Кошелёк',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.r16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Баланс',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '0 ₸',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Вывести'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
