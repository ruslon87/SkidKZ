// lib/features/onboarding/screens/buyer_onboarding_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class BuyerOnboardingScreen extends StatefulWidget {
  const BuyerOnboardingScreen({super.key});

  @override
  State<BuyerOnboardingScreen> createState() => _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState extends State<BuyerOnboardingScreen> {
  final _fullName = TextEditingController();
  final _city = TextEditingController(text: 'Алматы');
  final _street = TextEditingController();
  final _apartment = TextEditingController();
  final _comment = TextEditingController();
  final _contactPhone = TextEditingController();

  bool _accepted = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = fb.FirebaseAuth.instance.currentUser;
    _contactPhone.text = (u?.phoneNumber ?? '').trim();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _city.dispose();
    _street.dispose();
    _apartment.dispose();
    _comment.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    if (_fullName.text.trim().length < 2) {
      _toast('Введите имя');
      return false;
    }
    if (_city.text.trim().isEmpty) {
      _toast('Введите город');
      return false;
    }
    if (_street.text.trim().length < 5) {
      _toast('Введите адрес (улица/дом)');
      return false;
    }
    if (_contactPhone.text.trim().isEmpty) {
      _toast('Введите контактный телефон');
      return false;
    }
    if (!_accepted) {
      _toast('Нужно принять условия');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    final u = fb.FirebaseAuth.instance.currentUser;
    if (u == null) {
      _toast('Сессия истекла. Войдите снова.');
      context.go('/login');
      return;
    }

    if (!_validate()) return;

    setState(() => _loading = true);

    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(u.uid);

      await doc.set({
        'profiles': {
          'buyer': {
            'completed': true,
            'fullName': _fullName.text.trim(),
            'city': _city.text.trim(),
            'street': _street.text.trim(),
            'apartment': _apartment.text.trim(),
            'comment': _comment.text.trim(),
            'contactPhone': _contactPhone.text.trim(),
            'acceptedTerms': true,
            'acceptedAt': FieldValue.serverTimestamp(),
          }
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Куда вернуться после онбординга
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      if (next != null && next.isNotEmpty) {
        context.go(next);
      } else {
        context.go('/buyer/home');
      }
    } catch (e) {
      _toast('Ошибка сохранения: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Анкета покупателя'),
          automaticallyImplyLeading: !_loading,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Заполните данные для оформления заказов и доставки.',
              style: TextStyle(fontSize: 14),
            ),
            const Gap(16),

            TextField(
              controller: _fullName,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Имя и фамилия',
                hintText: 'Например: Иван Петров',
              ),
            ),
            const Gap(12),

            TextField(
              controller: _city,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Город',
                hintText: 'Алматы',
              ),
            ),
            const Gap(12),

            TextField(
              controller: _street,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Адрес (улица, дом)',
                hintText: 'Например: Абая 10',
              ),
            ),
            const Gap(12),

            TextField(
              controller: _apartment,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Квартира/офис (если есть)',
                hintText: 'Например: 45',
              ),
            ),
            const Gap(12),

            TextField(
              controller: _comment,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Комментарий курьеру (необязательно)',
                hintText: 'Подъезд, этаж, домофон...',
              ),
              maxLines: 2,
            ),
            const Gap(12),

            TextField(
              controller: _contactPhone,
              enabled: !_loading,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Контактный телефон',
                hintText: '+7XXXXXXXXXX',
              ),
            ),
            const Gap(16),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: _loading ? null : (v) => setState(() => _accepted = v ?? false),
              title: const Text('Я принимаю пользовательское соглашение и политику конфиденциальности'),
            ),
            const Gap(12),

            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
