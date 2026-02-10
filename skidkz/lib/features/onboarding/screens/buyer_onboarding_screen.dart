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

    for (final c in [
      _firstName,
      _lastName,
      _city,
      _street,
      _house,
      _apartment,
      _comment,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
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

  String _norm(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

  bool get _canSave {
    if (_loading || !_accepted) return false;
    if (_norm(_firstName.text).length < 2) return false;
    if (_norm(_lastName.text).length < 2) return false;
    if (_norm(_city.text).isEmpty) return false;
    if (_norm(_street.text).isEmpty) return false;
    if (_norm(_house.text).isEmpty) return false;
    if (_contactPhone.text.isEmpty) return false;
    return true;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final u = fb.FirebaseAuth.instance.currentUser;
    if (u == null) {
      context.go('/login');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .set({
        'profiles': {
          'buyer': {
            'completed': true,
            'firstName': _norm(_firstName.text),
            'lastName': _norm(_lastName.text),
            'fullName':
                '${_norm(_firstName.text)} ${_norm(_lastName.text)}',
            'city': _norm(_city.text),
            'street': _norm(_street.text),
            'house': _norm(_house.text),
            'apartment': _norm(_apartment.text),
            'comment': _norm(_comment.text),
            'contactPhone': _contactPhone.text,
            'acceptedTerms': true,
            'acceptedAt': FieldValue.serverTimestamp(),
          }
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      context.go('/cabinet');
    } catch (_) {
      _toast('Не удалось сохранить данные');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Анкета покупателя')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Эти данные используются для доставки и связи.',
            ),
            const Gap(16),

            TextField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            const Gap(12),
            TextField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Фамилия'),
            ),
            const Gap(16),

            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Город'),
            ),
            const Gap(12),
            TextField(
              controller: _street,
              decoration: const InputDecoration(labelText: 'Улица'),
            ),
            const Gap(12),
            TextField(
              controller: _house,
              decoration: const InputDecoration(labelText: 'Дом'),
            ),
            const Gap(12),
            TextField(
              controller: _apartment,
              decoration:
                  const InputDecoration(labelText: 'Квартира / офис'),
            ),
            const Gap(12),
            TextField(
              controller: _comment,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Комментарий курьеру',
              ),
            ),
            const Gap(16),

            TextField(
              controller: _contactPhone,
              enabled: false,
              decoration:
                  const InputDecoration(labelText: 'Телефон'),
            ),
            const Gap(16),

            CheckboxListTile(
              value: _accepted,
              onChanged: _loading
                  ? null
                  : (v) => setState(() => _accepted = v ?? false),
              title: const Text(
                  'Принимаю пользовательское соглашение'),
              contentPadding: EdgeInsets.zero,
            ),
            const Gap(12),

            ElevatedButton(
              onPressed: _canSave ? _save : null,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
