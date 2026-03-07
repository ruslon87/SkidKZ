// lib/features/auth/screens/login_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/core/widgets/app_gradient_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.nextPath,
    this.action,
    this.productId,
    this.qty,
  });

  final String? nextPath;
  final String? action;
  final String? productId;
  final int? qty;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginActionPayload {
  const _LoginActionPayload({
    required this.type,
    required this.productId,
    required this.qty,
  });

  final _LoginActionType type;
  final String productId;
  final int qty;
}

enum _LoginActionType {
  favToggle,
  cartAdd,
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+7');
  final _smsController = TextEditingController();
  final _smsFocus = FocusNode();

  String? _verificationId;
  bool _codeSent = false;

  bool _loadingSend = false;
  bool _loadingConfirm = false;
  bool _applyingPostLoginAction = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _smsFocus.dispose();
    super.dispose();
  }

  bool get _busy =>
      _loadingSend || _loadingConfirm || _applyingPostLoginAction;

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
    final t = widget.nextPath?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  GoRouter? get _r => GoRouter.maybeOf(context);

  bool _isProtectedBuyerPath(String path) {
    return path.startsWith('/buyer/favorites') ||
        path.startsWith('/buyer/cart') ||
        path.startsWith('/buyer/profile') ||
        path.startsWith('/buyer/orders');
  }

  void _goHomeOrNext() {
    final r = _r;
    if (r == null) {
      _toast('Навигация недоступна (Router не найден)');
      return;
    }

    final next = _next();

    // Если next указывает на protected path, а пользователь выбрал
    // "Продолжить без входа", уходим на home, чтобы не зациклиться на login.
    if (next == null || _isProtectedBuyerPath(next)) {
      r.go('/buyer/home');
      return;
    }

    r.go(next);
  }

  void _popOrGoHomeOrNext() {
    final r = _r;
    if (r == null) {
      _toast('Навигация недоступна (Router не найден)');
      return;
    }

    if (r.canPop()) {
      r.pop();
      return;
    }

    _goHomeOrNext();
  }

  _LoginActionPayload? _parsePendingAction() {
    final actionRaw = (widget.action ?? '').trim();
    final pid = (widget.productId ?? '').trim();
    final qty = widget.qty ?? 1;

    if (pid.isEmpty) return null;

    switch (actionRaw) {
      case 'fav':
        return _LoginActionPayload(
          type: _LoginActionType.favToggle,
          productId: pid,
          qty: 1,
        );
      case 'cart_add':
        return _LoginActionPayload(
          type: _LoginActionType.cartAdd,
          productId: pid,
          qty: qty <= 0 ? 1 : qty,
        );
      default:
        return null;
    }
  }

  Future<void> _applyPostLoginActionIfNeeded(fb.User user) async {
    final action = _parsePendingAction();
    if (action == null) return;

    setState(() => _applyingPostLoginAction = true);

    try {
      final db = FirebaseFirestore.instance;
      final uid = user.uid;

      if (action.type == _LoginActionType.favToggle) {
        final favRef = db
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(action.productId);

        final snap = await favRef.get();
        if (snap.exists) {
          await favRef.delete();
        } else {
          await favRef.set({
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (action.type == _LoginActionType.cartAdd) {
        final cartRef = db
            .collection('users')
            .doc(uid)
            .collection('cart')
            .doc(action.productId);

        final snap = await cartRef.get();
        final currentQty = (snap.data()?['qty'] as int?) ?? 0;
        final newQty = currentQty + action.qty;

        await cartRef.set({
          'qty': newQty,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } finally {
      if (mounted) {
        setState(() => _applyingPostLoginAction = false);
      }
    }
  }

  Future<void> _goAfterLogin() async {
    final r = _r;
    if (r == null) {
      _toast('Навигация недоступна (Router не найден)');
      return;
    }

    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _applyPostLoginActionIfNeeded(user);
    }

    final next = _next();
    r.go(next ?? '/cabinet');
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
          await _goAfterLogin();
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
      await _goAfterLogin();
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

    if (_codeSent) {
      setState(() {
        _codeSent = false;
        _smsController.clear();
        _verificationId = null;
      });
      return;
    }

    _popOrGoHomeOrNext();
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
                      onPressed: _busy ? null : _goHomeOrNext,
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
                        child: _loadingConfirm || _applyingPostLoginAction
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
