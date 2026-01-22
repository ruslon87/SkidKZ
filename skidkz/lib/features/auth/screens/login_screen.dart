import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/data/models/user_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (!_codeSent) ...[
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _codeSent = true;
                  });
                },
                child: const Text('Get Code'),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'SMS Code (Any 4 digits)'),
                keyboardType: TextInputType.number,
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: () {
                  // Mock Login as Buyer by default for phone login flow
                  ref.read(authProvider.notifier).login(UserRole.buyer);
                },
                child: const Text('Verify & Login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
