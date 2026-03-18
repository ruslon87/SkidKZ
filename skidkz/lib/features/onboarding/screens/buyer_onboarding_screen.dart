// lib/features/onboarding/screens/buyer_onboarding_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class BuyerOnboardingScreen extends StatefulWidget {
  const BuyerOnboardingScreen({super.key, this.nextPath});
  final String? nextPath;

  @override
  State<BuyerOnboardingScreen> createState() => _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState extends State<BuyerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Алматы');
  final _streetCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _kaspiPhoneCtrl = TextEditingController();
  bool _acceptedTerms = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _cityCtrl.dispose();
    _streetCtrl.dispose();
    _apartmentCtrl.dispose();
    _commentCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _kaspiPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Примите условия использования')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'profiles': {
            'buyer': {
              'completed': true,
              'firstName': _firstNameCtrl.text.trim(),
              'lastName': _lastNameCtrl.text.trim(),
              'fullName': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim(),
              'city': _cityCtrl.text.trim(),
              'street': _streetCtrl.text.trim(),
              'apartment': _apartmentCtrl.text.trim(),
              'comment': _commentCtrl.text.trim(),
              'contactPhone': _contactPhoneCtrl.text.trim(),
              'kaspiPhone': _kaspiPhoneCtrl.text.trim(),
              'acceptedTerms': true,
            }
          },
          'displayName': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      final next = widget.nextPath?.trim();
      if (next != null && next.isNotEmpty) {
        GoRouter.of(context).go(next);
      } else {
        GoRouter.of(context).go('/buyer/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заполните профиль'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Шапка
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Личные данные',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Нужны для оформления заказов и доставки',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Личные данные'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    ctrl: _firstNameCtrl, label: 'Имя', hint: 'Алибек',
                    icon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    ctrl: _lastNameCtrl, label: 'Фамилия', hint: 'Сейткали',
                    icon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите фамилию' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionTitle('Адрес доставки'),
            const SizedBox(height: 12),
            _field(
              ctrl: _cityCtrl, label: 'Город', hint: 'Алматы',
              icon: Icons.location_city_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите город' : null,
            ),
            const SizedBox(height: 12),
            _field(
              ctrl: _streetCtrl, label: 'Улица и дом', hint: 'ул. Абая, 150',
              icon: Icons.home_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите улицу и дом' : null,
            ),
            const SizedBox(height: 12),
            _field(
              ctrl: _apartmentCtrl, label: 'Квартира / офис (необязательно)',
              hint: 'кв. 42', icon: Icons.door_front_door_outlined,
            ),
            const SizedBox(height: 12),
            _field(
              ctrl: _commentCtrl, label: 'Комментарий к адресу (необязательно)',
              hint: 'Домофон 42, 3 этаж', icon: Icons.comment_outlined, maxLines: 2,
            ),
            const SizedBox(height: 24),

            _sectionTitle('Контактные данные'),
            const SizedBox(height: 12),
            _field(
              ctrl: _contactPhoneCtrl, label: 'Контактный телефон', hint: '+7 777 123 45 67',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите телефон' : null,
            ),
            const SizedBox(height: 24),

            _sectionTitle('Реквизиты Kaspi'),
            const SizedBox(height: 4),
            Text(
              'Номер телефона, привязанный к Kaspi Gold. Используется для получения вознаграждений, если вы станете партнером SkidKZ.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            _field(
              ctrl: _kaspiPhoneCtrl, label: 'Номер Kaspi (необязательно)',
              hint: '+7 777 123 45 67',
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
            ),
            const SizedBox(height: 24),

            // Согласие
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acceptedTerms ? theme.colorScheme.primary : Colors.grey.shade300,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'Я соглашаюсь с условиями использования платформы SkidKZ и политикой конфиденциальности',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Сохранить и продолжить',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: Colors.grey.shade600, letterSpacing: 0.5));
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
