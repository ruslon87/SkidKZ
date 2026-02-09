import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _startResendTimer([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = seconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSecondsLeft <= 1) {
        t.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10 || !phone.startsWith('+')) {
      _toast('Введите номер в формате +7XXXXXXXXXX');
      return;
    }

    if (_loading) return;
    if (_resendSecondsLeft > 0) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),

        // Автоподтверждение (иногда срабатывает на Android)
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            context.go('/cabinet');
          } on FirebaseAuthException catch (e) {
            if (!mounted) return;
            _toast('Auto sign-in ошибка: ${e.message ?? e.code}');
          } catch (e) {
            if (!mounted) return;
            _toast('Auto sign-in ошибка: $e');
          } finally {
            if (!mounted) return;
            setState(() => _loading = false);
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _loading = false);
          _toast('Ошибка отправки SMS: ${e.message ?? e.code}');
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;

          _verificationId = verificationId;

          // Важно: сразу показываем ввод кода, убираем loading,
          // иначе будет “кажется, ничего не произошло”
          setState(() {
            _codeSent = true;
            _loading = false;
          });

          _startResendTimer(60);
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          // timeout — это не ошибка, просто авто-ретрив не успел
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Ошибка: $e');
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

    if (_loading) return;
    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      // После входа сразу уходим в /cabinet (резолвер):
      // он создаст users/{uid} и отправит на onboarding/home
      context.go('/cabinet');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast('Ошибка входа: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      _toast('Ошибка входа: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_loading) return false;

    // На шаге ввода SMS — назад возвращает к вводу номера
    if (_codeSent) {
      setState(() {
        _codeSent = false;
        _verificationId = null;
        _codeController.clear();
      });
      return false;
    }

    // На шаге ввода номера — просто закрываем экран
    if (context.canPop()) {
      context.pop();
      return false;
    }

    // Если вдруг логин первый экран (редкий кейс)
    context.go('/buyer/home');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Вход по номеру v2'), // МАРКЕР: должен быть виден
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _loading ? null : () => _onWillPop(),
          ),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_codeSent) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'Номер телефона',
                        hintText: '+77770001122',
                      ),
                    ),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: (_loading || _resendSecondsLeft > 0) ? null : _sendCode,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _resendSecondsLeft > 0
                                  ? 'Повтор через $_resendSecondsLeft c'
                                  : 'Получить код',
                            ),
                    ),
                    const Gap(10),
                    const Text(
                      'После нажатия Firebase делает проверку, это может занять 1–3 секунды.',
                      style: TextStyle(color: Colors.black54),
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
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'SMS код',
                        hintText: 'Например: 438743',
                      ),
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
                      onPressed: (_loading || _resendSecondsLeft > 0) ? null : _sendCode,
                      child: Text(
                        _resendSecondsLeft > 0
                            ? 'Отправить повторно через $_resendSecondsLeft c'
                            : 'Отправить код повторно',
                      ),
                    ),
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

            // Блокер на время загрузки, чтобы нельзя было “протыкать” UI
            if (_loading)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: Colors.black.withOpacity(0.04),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
