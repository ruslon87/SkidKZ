// lib/features/auth/screens/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
  bool _loadingConfirm = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _smsFocus.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String _normalizePhone(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!s.startsWith('+')) s = '+$s';
    return s;
  }

  Future<void> _sendCode() async {
    if (_loadingSend || _loadingConfirm) return;

    final phone = _normalizePhone(_phoneController.text);
    if (phone.length < 10) {
      _toast('Введите номер телефона');
      return;
    }

    setState(() => _loadingSend = true);

    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (credential) async {
          // Автоверификация (редко, но бывает)
          try {
            await fb.FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            context.go('/cabinet');
          } catch (_) {
            // игнор — пользователь введёт код вручную
          }
        },

        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _loadingSend = false);
          _toast('Не удалось отправить код: ${e.message ?? e.code}');
        },

        codeSent: (verificationId, resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _loadingSend = false; // ВАЖНО: снимаем loading только когда код реально отправлен
          });

          Future.microtask(() {
            if (!mounted) return;
            _smsController.clear();
            _smsFocus.requestFocus();
          });
        },

        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          if (!mounted) return;
          // Если пользователь всё ещё ждёт — убираем спиннер, чтобы мог повторить
          if (_loadingSend) setState(() => _loadingSend = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingSend = false);
      _toast('Ошибка: $e');
    }
  }

  Future<void> _confirmCode() async {
    if (_loadingSend || _loadingConfirm) return;

    final smsCode = _smsController.text.trim();
    if (smsCode.length < 4) {
      _toast('Введите SMS-код');
      return;
    }
    if (_verificationId == null) {
      _toast('Код устарел. Запросите новый.');
      setState(() => _codeSent = false);
      return;
    }

    setState(() => _loadingConfirm = true);

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await fb.FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      context.go('/cabinet'); // дальше роутер сам решит: онбординг или home
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loadingConfirm = false);
      _toast('Неверный код: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingConfirm = false);
      _toast('Ошибка входа: $e');
    }
  }

  void _back() {
    if (_loadingSend || _loadingConfirm) return;

    if (_codeSent) {
      setState(() {
        _codeSent = false;
        _smsController.clear();
        _verificationId = null;
      });
      return;
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loadingSend || _loadingConfirm;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _back(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Вход по номеру'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _back,
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_codeSent) ...[
                  TextField(
                    controller: _phoneController,
                    enabled: !busy,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Номер телефона',
                      hintText: '+7XXXXXXXXXX',
                    ),
                    onSubmitted: (_) => busy ? null : _sendCode(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy ? null : _sendCode,
                      child: _loadingSend
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Получить код'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadingSend
                        ? 'Отправляем SMS…'
                        : 'Отправим SMS и перейдём к вводу кода.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ] else ...[
                  const Text('Введите код из SMS'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _smsController,
                    focusNode: _smsFocus,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'SMS код',
                    ),
                    onSubmitted: (_) => busy ? null : _confirmCode(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy ? null : _confirmCode,
                      child: _loadingConfirm
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Подтвердить и войти'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            setState(() {
                              _codeSent = false;
                              _smsController.clear();
                              _verificationId = null;
                            });
                          },
                    child: const Text('Изменить номер'),
                  ),
                  if (_loadingConfirm)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Проверяем код и входим…',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
