// lib/features/auth/screens/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/core/widgets/app_gradient_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.nextPath,
  });

  final String? nextPath;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+7');
  final _smsController = TextEditingController();
  final _smsFocus = FocusNode();

  String? _verificationId;
  bool _codeSent = false;

  bool _loadingSend = false;
  bool _loadingVerify = false;

  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _smsFocus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _loadingSend = true;
      _error = null;
    });

    final auth = fb.FirebaseAuth.instance;

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (credential) async {
          try {
            await auth.signInWithCredential(credential);
            if (!mounted) return;
            context.go(widget.nextPath ?? '/cabinet');
          } catch (e) {
            if (!mounted) return;
            setState(() => _error = e.toString());
          }
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _error = e.message ?? e.toString());
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });
          _smsFocus.requestFocus();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSend = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;

    setState(() {
      _loadingVerify = true;
      _error = null;
    });

    final auth = fb.FirebaseAuth.instance;

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsController.text.trim(),
      );

      await auth.signInWithCredential(credential);
      if (!mounted) return;
      context.go(widget.nextPath ?? '/cabinet');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingVerify = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Вход',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Введите номер телефона — пришлём SMS-код',
                      style: TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        hintText: '+7 777 777 77 77',
                      ),
                    ),

                    if (_codeSent) ...[
                      const SizedBox(height: 12),
                      TextField(
                        focusNode: _smsFocus,
                        controller: _smsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'SMS-код',
                          hintText: '123456',
                        ),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 18),

                    if (!_codeSent)
                      ElevatedButton(
                        onPressed: _loadingSend ? null : _sendCode,
                        child: _loadingSend
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Отправить код'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _loadingVerify ? null : _verifyCode,
                        child: _loadingVerify
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Подтвердить'),
                      ),

                    const SizedBox(height: 10),
                    const Text(
                      'Нажимая “Продолжить”, вы соглашаетесь с условиями сервиса.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
