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
  bool _loadingConfirm = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _smsFocus.dispose();
    super.dispose();
  }

  bool get _busy => _loadingSend || _loadingConfirm;

  void _toast(String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.maybeOf(context);
    m
      ?..clearSnackBars()
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
      // fallback, если по какой-то причине нет Router в дереве
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
      );
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
    if (_busy) return;

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
    if (_busy) return;

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

  Future<void> _handleBack() async {
    if (_busy) return;

    // 1) если на шаге ввода SMS — возвращаемся на ввод телефона
    if (_codeSent) {
      setState(() {
        _codeSent = false;
        _smsController.clear();
        _verificationId = null;
      });
      return;
    }

    // 2) пробуем закрыть экран обычным pop (если мы пришли сюда через push)
    final didPop = await Navigator.of(context).maybePop();
    if (didPop) return;

    // 3) fallback: возвращаемся на next либо на профиль/главную
    final next = _next();
    if (next != null) {
      _safeGo(next);
    } else {
      _safeGo('/buyer/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
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
                onPressed: _busy ? null : _handleBack,
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
                      enabled: !_busy,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+7 700 000 00 00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _sendCode,
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
                      // логика "как раньше": просто уйти назад/закрыть логин
                      onPressed: _busy ? null : _handleBack,
                      child: const Text('Продолжить без входа'),
                    ),
                  ] else ...[
                    const Text('Введите код из SMS'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _smsController,
                      focusNode: _smsFocus,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Код из SMS',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _confirmCode,
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
