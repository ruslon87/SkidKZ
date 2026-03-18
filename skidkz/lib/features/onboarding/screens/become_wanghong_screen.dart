// lib/features/onboarding/screens/become_wanghong_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/promo_service.dart';

class BecomeWanghongScreen extends StatefulWidget {
  const BecomeWanghongScreen({super.key});

  @override
  State<BecomeWanghongScreen> createState() => _BecomeWanghongScreenState();
}

class _BecomeWanghongScreenState extends State<BecomeWanghongScreen> {
  final _kaspiCtrl = TextEditingController();
  bool _accepted = false;
  bool _loading = false;
  bool _activated = false;
  String? _promoCode;

  // Данные из профиля покупателя
  String _firstName = '';
  String _lastName = '';
  String _existingKaspi = '';

  @override
  void initState() {
    super.initState();
    _loadBuyerData();
  }

  Future<void> _loadBuyerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};
    final buyer = (data['profiles'] as Map?)?.cast<String, dynamic>()?['buyer'] as Map<String, dynamic>? ?? {};
    final wanghong = (data['profiles'] as Map?)?.cast<String, dynamic>()?['wanghong'] as Map<String, dynamic>? ?? {};

    setState(() {
      _firstName = buyer['firstName']?.toString() ?? '';
      _lastName = buyer['lastName']?.toString() ?? '';
      _existingKaspi = buyer['kaspiPhone']?.toString() ?? wanghong['kaspiPhone']?.toString() ?? '';
      _kaspiCtrl.text = _existingKaspi;

      // Если уже партнер
      if (wanghong['promoCode'] != null) {
        _promoCode = wanghong['promoCode']?.toString();
        _activated = true;
      }
    });
  }

  Future<void> _activate() async {
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Примите условия партнерской программы')),
      );
      return;
    }
    if (_kaspiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите номер Kaspi для выплат')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await PromoService.activateWanghongRole(
        uid: user.uid,
        firstName: _firstName,
        lastName: _lastName,
        kaspiPhone: _kaspiCtrl.text.trim(),
      );
      // Получаем сгенерированный промокод
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final wanghong = (snap.data()?['profiles'] as Map?)?.cast<String, dynamic>()?['wanghong'] as Map<String, dynamic>? ?? {};
      setState(() {
        _promoCode = wanghong['promoCode']?.toString();
        _activated = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _kaspiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_activated && _promoCode != null) {
      return _SuccessScreen(promoCode: _promoCode!, onGoToDashboard: () {
        GoRouter.of(context).go('/wanghong/home');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Стать партнером'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Шапка
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade700, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Партнерская программа SkidKZ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Делитесь промокодом и зарабатывайте с каждой покупки',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Как это работает
          const Text('Как это работает',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _StepItem(
            number: '1',
            title: 'Получите личный промокод',
            subtitle: 'Уникальный код вида SKIDALI4827 будет создан автоматически',
            color: Colors.blue,
          ),
          _StepItem(
            number: '2',
            title: 'Делитесь в соцсетях',
            subtitle: 'Отправляйте промокод друзьям в WhatsApp, Instagram, Telegram',
            color: Colors.green,
          ),
          _StepItem(
            number: '3',
            title: 'Зарабатывайте',
            subtitle: 'Получайте % с каждого заказа, оформленного по вашему промокоду',
            color: Colors.orange,
          ),
          const SizedBox(height: 24),

          // Kaspi
          const Text('Реквизиты для выплат',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Укажите номер телефона, привязанный к Kaspi Gold. На него будут приходить выплаты.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _kaspiCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
            decoration: InputDecoration(
              labelText: 'Номер Kaspi',
              hintText: '+7 777 123 45 67',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Согласие
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _accepted ? Colors.amber.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Условия партнерской программы',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '• Вознаграждение составляет % от маржи каждого заказа\n'
                  '• Выплаты производятся на указанный Kaspi номер\n'
                  '• Минимальная сумма для вывода: 1 000 ₸\n'
                  '• Запрещен спам и недобросовестная реклама\n'
                  '• Платформа вправе изменить условия с уведомлением',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _accepted,
                      activeColor: Colors.amber.shade700,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'Я принимаю условия партнерской программы',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _activate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Получить промокод и стать партнером',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color color;
  const _StepItem({required this.number, required this.title, required this.subtitle, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final String promoCode;
  final VoidCallback onGoToDashboard;
  const _SuccessScreen({required this.promoCode, required this.onGoToDashboard});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star, size: 64, color: Colors.amber.shade700),
              ),
              const SizedBox(height: 24),
              const Text('Вы стали партнером!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Ваш личный промокод:',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: promoCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Промокод скопирован!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        promoCode,
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.copy, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Нажмите на промокод, чтобы скопировать',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onGoToDashboard,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Перейти в кабинет партнера',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
