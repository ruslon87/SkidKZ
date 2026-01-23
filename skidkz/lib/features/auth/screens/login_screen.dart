import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _loading = false;

  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _codeSent ? 'Введите код' : 'Вход по номеру';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (!_codeSent) ...[
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Номер телефона',
                  hintText: '+7XXXXXXXXXX',
                ),
                keyboardType: TextInputType.phone,
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendCode,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Получить код'),
                ),
              ),
            ] else ...[
              Text(
                'Код отправлен на ${_phoneController.text.trim()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Gap(12),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'SMS код',
                  hintText: '123456',
                ),
                keyboardType: TextInputType.number,
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyCode,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Подтвердить и войти'),
                ),
              ),
              const Gap(12),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _codeSent = false;
                          _otpController.clear();
                          _verificationId = null;
                        });
                      },
                child: const Text('Изменить номер'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      _show('Введите номер в формате +7XXXXXXXXXX');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,

        verificationCompleted: (PhoneAuthCredential credential) async {
          // Иногда Android может автоматически подтвердить SMS
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            Navigator.of(context).pop(); // вернёмся назад — роутер сам сделает redirect
          } catch (e) {
            if (mounted) _show('Автовход не удался: $e');
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          final msg = e.message ?? e.code;
          _show('Ошибка отправки SMS: $msg');
        },

        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeSent = true;
          });
          _show('Код отправлен');
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          // просто сохраняем, чтобы можно было ввести код вручную
          _verificationId = verificationId;
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpController.text.trim();
    final vid = _verificationId;

    if (vid == null) {
      _show('Сначала запросите код');
      return;
    }
    if (code.length < 4) {
      _show('Введите корректный код');
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      Navigator.of(context).pop(); // вернёмся назад — роутер сделает redirect
    } on FirebaseAuthException catch (e) {
      _show('Ошибка подтверждения: ${e.message ?? e.code}');
    } catch (e) {
      _show('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
