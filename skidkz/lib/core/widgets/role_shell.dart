// lib/features/auth/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/widgets/app_gradient_background.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Заглушка: никаких PopScope/двойных выходов.
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Выбор роли'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Временно отключено.\nРоли подключим позже поэтапно.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
