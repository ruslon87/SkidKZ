import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+7');
  final _codeController = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;

  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      _toast('Введите номер в формате +7XXXXXXXXXX');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            // редирект сделает GoRouter по authStateChanges
          } catch (e) {
            if (!mounted) return;
            _toast('Auto sign-in ошибка: $e');
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          _toast('Ошибка отправки SMS: ${e.message ?? e.code}');
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          _verificationId = verificationId;

          setState(() {
            _codeSent = true;
          });
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    final vid = _verificationId;

    if (vid == null) {
      _toast('Сначала запросите код');
      return;
    }

    if (code.length < 4) {
      _toast('Введите SMS код');
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      return;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast('Ошибка входа: ${e.message ?? e.code}');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (_loading) return;

        // вместо сворачивания приложения — уходим на главную витрину
        context.go('/buyer/home');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Вход по номеру')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_codeSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Номер телефона',
                    hintText: '+77770001122',
                  ),
                  enabled: !_loading,
                ),
                const Gap(16),
                ElevatedButton(
                  onPressed: _loading ? null : _sendCode,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Получить код'),
                ),
              ] else ...[
                Text(
                  'Код отправлен на ${_phoneController.text.trim()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Gap(12),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'SMS код',
                    hintText: 'Например: 438743',
                  ),
                  enabled: !_loading,
                ),
                const Gap(16),
                ElevatedButton(
                  onPressed: _loading ? null : _verifyCode,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Подтвердить и войти'),
                ),
                const Gap(8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() {
                            _codeSent = false;
                            _verificationId = null;
                            _codeController.clear();
                          });
                        },
                  child: const Text('Изменить номер'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
