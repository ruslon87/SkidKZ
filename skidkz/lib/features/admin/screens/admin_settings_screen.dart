// lib/features/admin/screens/admin_settings_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  // Контроллеры для полей
  final _platformCommissionCtrl = TextEditingController();
  final _wanghongCommissionCtrl = TextEditingController();
  final _holdDaysCtrl = TextEditingController();
  final _minWithdrawCtrl = TextEditingController();
  final _maxPromoDiscountCtrl = TextEditingController();
  bool _maintenanceMode = false;
  bool _registrationOpen = true;
  bool _sellerRegistrationOpen = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _platformCommissionCtrl.dispose();
    _wanghongCommissionCtrl.dispose();
    _holdDaysCtrl.dispose();
    _minWithdrawCtrl.dispose();
    _maxPromoDiscountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('platform').get();
      final data = doc.data() ?? {};
      setState(() {
        _platformCommissionCtrl.text = (data['platformCommissionPercent'] ?? 10).toString();
        _wanghongCommissionCtrl.text = (data['wanghongCommissionPercent'] ?? 5).toString();
        _holdDaysCtrl.text = (data['holdDays'] ?? 7).toString();
        _minWithdrawCtrl.text = (data['minWithdrawAmount'] ?? 1000).toString();
        _maxPromoDiscountCtrl.text = (data['maxPromoDiscountPercent'] ?? 20).toString();
        _maintenanceMode = data['maintenanceMode'] == true;
        _registrationOpen = data['registrationOpen'] != false;
        _sellerRegistrationOpen = data['sellerRegistrationOpen'] != false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _platformCommissionCtrl.text = '10';
        _wanghongCommissionCtrl.text = '5';
        _holdDaysCtrl.text = '7';
        _minWithdrawCtrl.text = '1000';
        _maxPromoDiscountCtrl.text = '20';
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('platform').set({
        'platformCommissionPercent': double.tryParse(_platformCommissionCtrl.text) ?? 10,
        'wanghongCommissionPercent': double.tryParse(_wanghongCommissionCtrl.text) ?? 5,
        'holdDays': int.tryParse(_holdDaysCtrl.text) ?? 7,
        'minWithdrawAmount': double.tryParse(_minWithdrawCtrl.text) ?? 1000,
        'maxPromoDiscountPercent': double.tryParse(_maxPromoDiscountCtrl.text) ?? 20,
        'maintenanceMode': _maintenanceMode,
        'registrationOpen': _registrationOpen,
        'sellerRegistrationOpen': _sellerRegistrationOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки сохранены'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Настройки платформы'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Сохранить'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Финансовые настройки
                  _SectionHeader(title: 'Финансы', icon: Icons.account_balance_wallet_rounded),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _NumberField(
                        controller: _platformCommissionCtrl,
                        label: 'Комиссия платформы (%)',
                        hint: 'Например: 10',
                        suffix: '%',
                        min: 0,
                        max: 50,
                      ),
                      const Divider(height: 24),
                      _NumberField(
                        controller: _wanghongCommissionCtrl,
                        label: 'Комиссия партнёра (%)',
                        hint: 'Например: 5',
                        suffix: '%',
                        min: 0,
                        max: 50,
                      ),
                      const Divider(height: 24),
                      _NumberField(
                        controller: _holdDaysCtrl,
                        label: 'Холд выплат (дней)',
                        hint: 'Например: 7',
                        suffix: 'дн',
                        min: 0,
                        max: 90,
                        isInt: true,
                      ),
                      const Divider(height: 24),
                      _NumberField(
                        controller: _minWithdrawCtrl,
                        label: 'Минимальная сумма выплаты',
                        hint: 'Например: 1000',
                        suffix: '₸',
                        min: 0,
                        max: 100000,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Промокоды
                  _SectionHeader(title: 'Промокоды', icon: Icons.local_offer_rounded),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _NumberField(
                        controller: _maxPromoDiscountCtrl,
                        label: 'Макс. скидка по промокоду (%)',
                        hint: 'Например: 20',
                        suffix: '%',
                        min: 0,
                        max: 100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Управление доступом
                  _SectionHeader(title: 'Доступ', icon: Icons.security_rounded),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SwitchRow(
                        label: 'Регистрация покупателей',
                        subtitle: 'Разрешить новым пользователям регистрироваться',
                        value: _registrationOpen,
                        onChanged: (v) => setState(() => _registrationOpen = v),
                        activeColor: Colors.green,
                      ),
                      const Divider(height: 24),
                      _SwitchRow(
                        label: 'Регистрация продавцов',
                        subtitle: 'Разрешить новым продавцам подавать заявки',
                        value: _sellerRegistrationOpen,
                        onChanged: (v) => setState(() => _sellerRegistrationOpen = v),
                        activeColor: Colors.blue,
                      ),
                      const Divider(height: 24),
                      _SwitchRow(
                        label: 'Режим обслуживания',
                        subtitle: 'Приложение будет недоступно для пользователей',
                        value: _maintenanceMode,
                        onChanged: (v) => setState(() => _maintenanceMode = v),
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Управление промокодами (список)
                  _SectionHeader(title: 'Активные промокоды', icon: Icons.confirmation_number_rounded),
                  const SizedBox(height: 12),
                  _PromoCodesSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _PromoCodesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('roles', arrayContains: 'wanghong')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        // Fallback
        if (snap.hasError) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'wanghong').snapshots(),
            builder: (ctx, snap2) {
              if (!snap2.hasData) return const SizedBox.shrink();
              return _buildPromoList(ctx, snap2.data?.docs ?? []);
            },
          );
        }
        return _buildPromoList(context, snap.data?.docs ?? []);
      },
    );
  }

  Widget _buildPromoList(BuildContext context, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: Center(child: Text('Нет активных партнёров', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: docs.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final data = doc.data();
          final profilesRaw = data['profiles'];
          final profiles = (profilesRaw is Map) ? profilesRaw.cast<String, dynamic>() : <String, dynamic>{};
          final wanghongRaw = profiles['wanghong'];
          final wanghong = (wanghongRaw is Map) ? wanghongRaw.cast<String, dynamic>() : <String, dynamic>{};
          final buyerRaw = profiles['buyer'];
          final buyer = (buyerRaw is Map) ? buyerRaw.cast<String, dynamic>() : <String, dynamic>{};
          final promoCode = wanghong['promoCode']?.toString() ?? '-';
          final firstName = buyer['firstName']?.toString() ?? '';
          final lastName = buyer['lastName']?.toString() ?? '';
          final fullName = '$firstName $lastName'.trim();
          final phone = data['phone']?.toString() ?? '-';
          final totalSales = (wanghong['totalSales'] as num?)?.toInt() ?? 0;
          final isActive = wanghong['isActive'] != false;

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(promoCode, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                title: Text(fullName.isNotEmpty ? fullName : phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('Продаж: $totalSales', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Активен' : 'Отключён',
                    style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                onTap: () => _togglePromoCode(context, doc.id, promoCode, isActive),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _togglePromoCode(BuildContext context, String docId, String promoCode, bool currentlyActive) async {
    final action = currentlyActive ? 'отключить' : 'включить';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${currentlyActive ? "Отключить" : "Включить"} промокод?'),
        content: Text('Вы хотите $action промокод "$promoCode"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: currentlyActive ? Colors.red : Colors.green, foregroundColor: Colors.white),
            child: Text(currentlyActive ? 'Отключить' : 'Включить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'profiles.wanghong.isActive': !currentlyActive,
      });
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final double min;
  final double max;
  final bool isInt;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.min,
    required this.max,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(hint, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        SizedBox(
          width: 90,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
            validator: (v) {
              final n = isInt ? int.tryParse(v ?? '') : double.tryParse(v ?? '');
              if (n == null) return 'Число';
              if (n < min || n > max) return '$min-$max';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }
}
