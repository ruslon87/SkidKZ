// lib/features/onboarding/screens/buyer_onboarding_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerOnboardingScreen extends StatefulWidget {
  const BuyerOnboardingScreen({
    super.key,
    this.nextPath,
  });

  final String? nextPath;

  @override
  State<BuyerOnboardingScreen> createState() => _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState extends State<BuyerOnboardingScreen> {
  final _fullNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Алматы');
  final _streetCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  bool _acceptedTerms = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _cityCtrl.dispose();
    _streetCtrl.dispose();
    _apartmentCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login?next=%2Fonboarding%2Fbuyer');
      return;
    }

    final fullName = _fullNameCtrl.text.trim();
    final city = _cityCtrl.text.trim();

    if (fullName.isEmpty) {
      setState(() => _error = 'Введите ФИО');
      return;
    }
    if (city.isEmpty) {
      setState(() => _error = 'Введите город');
      return;
    }
    if (!_acceptedTerms) {
      setState(() => _error = 'Подтвердите согласие с условиями');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('users').doc(user.uid);
      final existing = await ref.get();

      final nowTs = FieldValue.serverTimestamp();

      if (!existing.exists) {
        await ref.set({
          'uid': user.uid,
          'phone': user.phoneNumber ?? '',
          'roles': ['buyer'],
          'activeRole': 'buyer',
          'createdAt': nowTs,
          'updatedAt': nowTs,
          'profiles': {
            'buyer': {
              'completed': true,
              'fullName': fullName,
              'city': city,
              'street': _streetCtrl.text.trim(),
              'apartment': _apartmentCtrl.text.trim(),
              'comment': _commentCtrl.text.trim(),
              'contactPhone': user.phoneNumber ?? '',
              'acceptedTerms': true,
            },
            'seller': {'completed': false},
            'wanghong': {'completed': false},
          },
        });
      } else {
        await ref.set({
          'uid': user.uid,
          'phone': user.phoneNumber ?? '',
          'updatedAt': nowTs,
          'roles': FieldValue.arrayUnion(['buyer']),
          'activeRole': 'buyer',
          'profiles': {
            'buyer': {
              'completed': true,
              'fullName': fullName,
              'city': city,
              'street': _streetCtrl.text.trim(),
              'apartment': _apartmentCtrl.text.trim(),
              'comment': _commentCtrl.text.trim(),
              'contactPhone': user.phoneNumber ?? '',
              'acceptedTerms': true,
            },
          },
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      final next = widget.nextPath?.trim();
      context.go((next != null && next.isNotEmpty) ? next : '/buyer/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация покупателя')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Заполните профиль, чтобы завершить регистрацию.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fullNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'ФИО'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cityCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Город'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _streetCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Улица'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _apartmentCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Квартира / дом'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Комментарий для доставки'),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
            title: const Text('Согласен с условиями сервиса'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Завершить регистрацию'),
          ),
        ],
      ),
    );
  }
}
