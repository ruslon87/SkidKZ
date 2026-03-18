// lib/features/onboarding/screens/seller_onboarding_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SellerOnboardingScreen extends StatefulWidget {
  const SellerOnboardingScreen({super.key, this.nextPath});
  final String? nextPath;

  @override
  State<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends State<SellerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _storeDescCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Алматы');
  final _addressCtrl = TextEditingController();
  final _binCtrl = TextEditingController();
  final _kaspiPhoneCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  bool _isServiceSeller = false;
  bool _acceptedOffer = false;
  bool _saving = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _storeDescCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _binCtrl.dispose();
    _kaspiPhoneCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedOffer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Примите оферту для продавцов')),
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
            'seller': {
              'completed': true,
              'storeName': _storeNameCtrl.text.trim(),
              'storeDescription': _storeDescCtrl.text.trim(),
              'ownerName': _ownerNameCtrl.text.trim(),
              'ownerPhone': _ownerPhoneCtrl.text.trim(),
              'city': _cityCtrl.text.trim(),
              'address': _addressCtrl.text.trim(),
              'bin': _binCtrl.text.trim(),
              'kaspiPhone': _kaspiPhoneCtrl.text.trim(),
              'instagramUrl': _instagramCtrl.text.trim(),
              'isServiceSeller': _isServiceSeller,
              'status': 'pending', // ждет одобрения администратора
              'offerAccepted': true,
              'submittedAt': FieldValue.serverTimestamp(),
            }
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      // Показываем сообщение об ожидании проверки
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Заявка отправлена!'),
          content: const Text(
            'Ваша заявка на регистрацию магазина отправлена на проверку. '
            'Администратор рассмотрит её в течение 1-2 рабочих дней. '
            'После одобрения вы сможете добавлять товары.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      final next = widget.nextPath?.trim();
      if (next != null && next.isNotEmpty) {
        GoRouter.of(context).go(next);
      } else {
        GoRouter.of(context).go('/seller/home');
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
        title: const Text('Регистрация магазина'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _save();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving && _currentStep == 2
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_currentStep < 2 ? 'Далее' : 'Отправить заявку'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Назад'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // Шаг 1: О магазине
            Step(
              title: const Text('О магазине'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    ctrl: _storeNameCtrl,
                    label: 'Название магазина / бренда',
                    hint: 'Например: Шинный Центр Алматы',
                    icon: Icons.store_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    ctrl: _storeDescCtrl,
                    label: 'Описание (необязательно)',
                    hint: 'Что вы продаете, ваши преимущества...',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    ctrl: _instagramCtrl,
                    label: 'Instagram / сайт (необязательно)',
                    hint: '@mystore или https://mystore.kz',
                    icon: Icons.link_outlined,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isServiceSeller ? 'Тип: Услуги' : 'Тип: Товары',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _isServiceSeller
                                    ? 'Вы продаете услуги (ремонт, обучение и т.д.)'
                                    : 'Вы продаете физические товары',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isServiceSeller,
                          onChanged: (v) => setState(() => _isServiceSeller = v),
                          activeColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Шаг 2: Реквизиты
            Step(
              title: const Text('Реквизиты'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _field(
                    ctrl: _ownerNameCtrl,
                    label: 'ФИО владельца / ответственного',
                    hint: 'Иванов Иван Иванович',
                    icon: Icons.person_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите ФИО' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    ctrl: _ownerPhoneCtrl,
                    label: 'Контактный телефон',
                    hint: '+7 777 123 45 67',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите телефон' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    ctrl: _cityCtrl,
                    label: 'Город',
                    hint: 'Алматы',
                    icon: Icons.location_city_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите город' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    ctrl: _addressCtrl,
                    label: 'Адрес магазина / офиса',
                    hint: 'ул. Абая, 150, оф. 5',
                    icon: Icons.location_on_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите адрес' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    ctrl: _binCtrl,
                    label: 'БИН / ИИН (необязательно)',
                    hint: '123456789012',
                    icon: Icons.business_outlined,
                    keyboardType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            ),

            // Шаг 3: Kaspi и оферта
            Step(
              title: const Text('Kaspi и оферта'),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Укажите номер Kaspi для получения выплат от платформы',
                            style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    ctrl: _kaspiPhoneCtrl,
                    label: 'Номер Kaspi',
                    hint: '+7 777 123 45 67',
                    icon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите номер Kaspi' : null,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _acceptedOffer ? theme.colorScheme.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Оферта продавца',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Размещая товары на платформе SkidKZ, вы соглашаетесь:\n'
                          '• Предоставлять достоверную информацию о товарах\n'
                          '• Выполнять заказы в указанные сроки\n'
                          '• Платформа берет комиссию согласно тарифам\n'
                          '• Выплаты производятся на указанный Kaspi номер',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptedOffer,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (v) => setState(() => _acceptedOffer = v ?? false),
                            ),
                            const Expanded(
                              child: Text(
                                'Я принимаю условия оферты для продавцов SkidKZ',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
