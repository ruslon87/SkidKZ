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

  String? _next() {
    final next = widget.nextPath;
    if (next == null) return null;
    final t = next.trim();
    return t.isEmpty ? null : t;
  }

  GoRouter? get _r => GoRouter.maybeOf(context);

  void _safeGo(String path) {
    final r = _r;
    if (r == null) {
      _toast('Навигация недоступна (Router не найден)');
      return;
    }
    r.go(path);
  }

  void _safePush(String path) {
    final r = _r;
    if (r == null) {
      _toast('Навигация недоступна (Router не найден)');
      return;
    }
    r.push(path);
  }

  void _goAfterLogin() {
    final next = _next();
    if (next != null) {
      _safeGo(next);
    } else {
      _safeGo('/cabinet');
    }
  }

  Future<void> _sendCode() async {
    if (_loadingSend || _loadingConfirm) return;

    final phone = _normalizePhone(_phoneController.text);
    if (phone.length < 8) {
      _toast('Введите номер телефона');
      return;
    }

    setState(() => _loadingSend = true);

    await fb.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        try {
          await fb.FirebaseAuth.instance.signInWithCredential(cred);
          if (!mounted) return;
          _goAfterLogin();
        } catch (e) {
          if (!mounted) return;
          _toast('Не удалось войти: $e');
        } finally {
          if (!mounted) return;
          setState(() => _loadingSend = false);
        }
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() => _loadingSend = false);
        _toast('Ошибка: ${e.message ?? e.code}');
      },
      codeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _loadingSend = false;
          _verificationId = verificationId;
          _codeSent = true;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _smsFocus.requestFocus();
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _confirmCode() async {
    if (_loadingSend || _loadingConfirm) return;

    final code = _smsController.text.trim();
    if (code.length < 4) {
      _toast('Введите код из SMS');
      return;
    }

    final verId = _verificationId;
    if (verId == null) {
      _toast('Сначала запросите код');
      return;
    }

    setState(() => _loadingConfirm = true);

    try {
      final cred = fb.PhoneAuthProvider.credential(
        verificationId: verId,
        smsCode: code,
      );
      await fb.FirebaseAuth.instance.signInWithCredential(cred);

      if (!mounted) return;
      _goAfterLogin();
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast(e.message ?? 'Ошибка входа');
    } catch (e) {
      if (!mounted) return;
      _toast('Ошибка: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loadingConfirm = false);
    }
  }

  Future<void> _back() async {
    if (_loadingSend || _loadingConfirm) return;

    if (_codeSent) {
      setState(() {
        _codeSent = false;
        _smsController.clear();
        _verificationId = null;
      });
      return;
    }

    // ВАЖНО: НЕ context.pop/canPop (это go_router extensions)
    final didPop = await Navigator.of(context).maybePop();
    if (didPop) return;

    _safeGo('/buyer/home');
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loadingSend || _loadingConfirm;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: AppGradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Вход по номеру'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: busy ? null : _back,
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_codeSent) ...[
                    const Text('Номер телефона'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      enabled: !busy,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+7 700 000 00 00',
                      ),
                    ),
                    const SizedBox(height: 12),
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
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: busy ? null : () => _safePush('/buyer/home'),
                      child: const Text('Продолжить без входа'),
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
                        hintText: 'Код из SMS',
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            : const Text('Подтвердить'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
