import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AuthStep { phone, sms }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+7');
  final _smsController = TextEditingController();
  final _smsFocus = FocusNode();

  AuthStep _step = AuthStep.phone;
  bool _loading = false;
  String? _verificationId;

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
    if (_loading) return;

    final phone = _normalizePhone(_phoneController.text);
    if (phone.length < 10) {
      _toast('Введите номер телефона');
      return;
    }

    setState(() {
      _loading = true;
      _step = AuthStep.sms; // ⬅️ ВАЖНО: UI меняется СРАЗУ
    });

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
          if (!mounted) return;
          setState(() {
            _loading = false;
            _step = AuthStep.phone;
          });
          _toast('Не удалось отправить код');
        },

        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _loading = false;
          });
          Future.microtask(() => _smsFocus.requestFocus());
        },

        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          if (!mounted) return;
          setState(() => _loading = false);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = AuthStep.phone;
      });
      _toast('Ошибка отправки кода');
    }
  }

  Future<void> _confirmCode() async {
    if (_loading) return;

    if (_verificationId == null) {
      _toast('Код устарел. Запросите новый.');
      setState(() => _step = AuthStep.phone);
      return;
    }

    final code = _smsController.text.trim();
    if (code.length < 4) {
      _toast('Введите код');
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      await fb.FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      context.go('/cabinet');
    } on fb.FirebaseAuthException {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Неверный код');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Ошибка входа');
    }
  }

  void _back() {
    if (_loading) return;

    if (_step == AuthStep.sms) {
      setState(() {
        _step = AuthStep.phone;
        _smsController.clear();
        _verificationId = null;
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _back(),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Вход'),
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
                if (_step == AuthStep.phone) ...[
                  TextField(
                    controller: _phoneController,
                    enabled: !_loading,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Номер телефона',
                      hintText: '+7XXXXXXXXXX',
                    ),
                    onSubmitted: (_) => _sendCode(),
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
                          : const Text('Продолжить'),
                    ),
                  ),
                ] else ...[
                  const Text('Введите код из SMS'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _smsController,
                    focusNode: _smsFocus,
                    enabled: !_loading,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Код'),
                    onSubmitted: (_) => _confirmCode(),
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
                          : const Text('Войти'),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _back,
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
