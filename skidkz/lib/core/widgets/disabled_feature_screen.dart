// lib/core/widgets/disabled_feature_screen.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/widgets/app_gradient_background.dart';

class DisabledFeatureScreen extends StatelessWidget {
  final String title;
  const DisabledFeatureScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Временно отключено.\nПодключим позже поэтапно.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
