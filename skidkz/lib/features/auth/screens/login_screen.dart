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
  bool _loading = false;

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
    final phone = _normalizePhone(_phoneController.text);
    if (phone.length < 10) {
      _toast('Введите номер телефона');
      return;
    }

    setState(() => _loading = true);

    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await fb.FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            context.go('/cabinet');
          } catch (_) {}
        },
        verificationFailed: (e) {
          _toast('Не удалось отправить код: ${e.message ?? e.code}');
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });

          Future.microtask(() {
            if (!mounted) return;
            _smsController.clear();
            _smsFocus.requestFocus();
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _toast('Ошибка: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmCode() async {
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

    setState(() => _loading = true);

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await fb.FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      context.go('/cabinet');
    } on fb.FirebaseAuthException catch (e) {
      _toast('Неверный код: ${e.message ?? e.code}');
    } catch (e) {
      _toast('Ошибка входа: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _back() {
    if (_loading) return;

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
                    enabled: !_loading,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Номер телефона',
                      hintText: '+7XXXXXXXXXX',
                    ),
                    onSubmitted: (_) => _loading ? null : _sendCode(),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
                  const Text(
                    'Отправляем SMS и проверяем номер. Это может занять несколько секунд.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ] else ...[
                  const Text('Введите код из SMS'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _smsController,
                    focusNode: _smsFocus,
                    enabled: !_loading,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'SMS код',
                    ),
                    onSubmitted: (_) => _loading ? null : _confirmCode(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirmCode,
                      child: _loading
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
                    onPressed: _loading
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
