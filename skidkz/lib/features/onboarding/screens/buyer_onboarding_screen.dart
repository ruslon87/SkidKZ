// lib/features/onboarding/screens/buyer_onboarding_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class BuyerOnboardingScreen extends StatefulWidget {
  const BuyerOnboardingScreen({super.key});

  @override
  State<BuyerOnboardingScreen> createState() => _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState extends State<BuyerOnboardingScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  final _city = TextEditingController(text: 'Алматы');

  final _street = TextEditingController();
  final _house = TextEditingController();
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

    // Автопересчёт состояния кнопки (чтобы "Сохранить" оживала сама)
    for (final c in [
      _firstName,
      _lastName,
      _city,
      _street,
      _house,
      _apartment,
      _comment,
    ]) {
      c.addListener(_rebuild);
    }
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _city,
      _street,
      _house,
      _apartment,
      _comment,
    ]) {
      c.removeListener(_rebuild);
    }

    _firstName.dispose();
    _lastName.dispose();
    _city.dispose();
    _street.dispose();
    _house.dispose();
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

  String _norm(String s) {
    // trim + убрать двойные пробелы
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }

  bool get _canSave {
    if (_loading) return false;
    if (!_accepted) return false;

    final first = _norm(_firstName.text);
    final last = _norm(_lastName.text);
    final city = _norm(_city.text);
    final street = _norm(_street.text);
    final house = _norm(_house.text);
    final phone = _norm(_contactPhone.text);

    if (first.length < 2) return false;
    if (last.length < 2) return false;
    if (city.isEmpty) return false;
    if (street.length < 2) return false;
    if (house.isEmpty) return false;
    if (phone.isEmpty) return false;

    return true;
  }

  bool _validateOrToast() {
    final first = _norm(_firstName.text);
    final last = _norm(_lastName.text);
    final city = _norm(_city.text);
    final street = _norm(_street.text);
    final house = _norm(_house.text);
    final phone = _norm(_contactPhone.text);

    if (first.length < 2) {
      _toast('Введите имя');
      return false;
    }
    if (last.length < 2) {
      _toast('Введите фамилию');
      return false;
    }
    if (city.isEmpty) {
      _toast('Введите город');
      return false;
    }
    if (street.length < 2) {
      _toast('Введите улицу');
      return false;
    }
    if (house.isEmpty) {
      _toast('Введите номер дома');
      return false;
    }
    if (phone.isEmpty) {
      _toast('Не удалось получить номер телефона. Войдите заново.');
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
      if (mounted) context.go('/login');
      return;
    }

    if (!_validateOrToast()) return;

    setState(() => _loading = true);

    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(u.uid);

      final first = _norm(_firstName.text);
      final last = _norm(_lastName.text);

      final city = _norm(_city.text);
      final street = _norm(_street.text);
      final house = _norm(_house.text);
      final apartment = _norm(_apartment.text);
      final comment = _norm(_comment.text);

      final phone = _norm(_contactPhone.text);

      await doc.set({
        'profiles': {
          'buyer': {
            'completed': true,

            // Для удобства можно хранить и fullName, и раздельные поля
            'firstName': first,
            'lastName': last,
            'fullName': '$first $last',

            'city': city,
            'street': street,
            'house': house,
            'apartment': apartment,
            'comment': comment,

            'contactPhone': phone,

            'acceptedTerms': true,
            'acceptedAt': FieldValue.serverTimestamp(),
          }
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Куда вернуться после онбординга:
      // 1) если передан next - идём туда
      // 2) иначе лучше идти в /cabinet, чтобы app_router сам разрулил роль/домой
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      if (next != null && next.isNotEmpty) {
        context.go(next);
      } else {
        context.go('/cabinet');
      }
    } on FirebaseException catch (e) {
      _toast('Не удалось сохранить. Попробуйте ещё раз.');
      // если нужно для отладки: _toast('Ошибка: ${e.code}');
    } catch (_) {
      _toast('Не удалось сохранить. Попробуйте ещё раз.');
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

            // Имя
            TextField(
              controller: _firstName,
              enabled: !_loading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Имя',
                hintText: 'Например: Иван',
              ),
            ),
            const Gap(12),

            // Фамилия
            TextField(
              controller: _lastName,
              enabled: !_loading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Фамилия',
                hintText: 'Например: Петров',
              ),
            ),
            const Gap(16),

            // Город
            TextField(
              controller: _city,
              enabled: !_loading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Город',
                hintText: 'Алматы',
              ),
            ),
            const Gap(12),

            // Улица
            TextField(
              controller: _street,
              enabled: !_loading,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Улица',
                hintText: 'Например: Абая',
              ),
            ),
            const Gap(12),

            // Дом
            TextField(
              controller: _house,
              enabled: !_loading,
              keyboardType: TextInputType.streetAddress,
              decoration: const InputDecoration(
                labelText: 'Дом',
                hintText: 'Например: 10',
              ),
            ),
            const Gap(12),

            // Квартира/офис
            TextField(
              controller: _apartment,
              enabled: !_loading,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Квартира/офис (если есть)',
                hintText: 'Например: 45',
              ),
            ),
            const Gap(16),

            TextField(
              controller: _comment,
              enabled: !_loading,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Комментарий курьеру (необязательно)',
                hintText: 'Подъезд, этаж, домофон...',
              ),
              maxLines: 2,
            ),
            const Gap(16),

            // Телефон — read-only (только из auth)
            TextField(
              controller: _contactPhone,
              enabled: false,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Контактный телефон',
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
              onPressed: _canSave ? _save : null,
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
