// lib/features/admin/screens/admin_settings_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/services/pricing_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  // Контроллеры для общих настроек
  final _holdDaysCtrl = TextEditingController();
  final _minWithdrawCtrl = TextEditingController();
  final _maxPromoDiscountCtrl = TextEditingController();
  bool _maintenanceMode = false;
  bool _registrationOpen = true;
  bool _sellerRegistrationOpen = true;

  // Ценовые пороги
  List<PricingTier> _tiers = [];
  bool _tiersDirty = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _holdDaysCtrl.dispose();
    _minWithdrawCtrl.dispose();
    _maxPromoDiscountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadSettings(), _loadTiers()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('platform')
          .get();
      final data = doc.data() ?? {};
      if (mounted) {
        setState(() {
          _holdDaysCtrl.text = (data['holdDays'] ?? 7).toString();
          _minWithdrawCtrl.text =
              (data['minWithdrawAmount'] ?? 1000).toString();
          _maxPromoDiscountCtrl.text =
              (data['maxPromoDiscountPercent'] ?? 20).toString();
          _maintenanceMode = data['maintenanceMode'] == true;
          _registrationOpen = data['registrationOpen'] != false;
          _sellerRegistrationOpen = data['sellerRegistrationOpen'] != false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _holdDaysCtrl.text = '7';
          _minWithdrawCtrl.text = '1000';
          _maxPromoDiscountCtrl.text = '20';
        });
      }
    }
  }

  Future<void> _loadTiers() async {
    final tiers = await PricingService.loadTiers();
    if (mounted) setState(() => _tiers = tiers);
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Future.wait([
        _saveSettings(),
        if (_tiersDirty) PricingService.saveTiers(_tiers),
      ]);
      if (mounted) {
        setState(() => _tiersDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Настройки сохранены'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSettings() async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('platform')
        .set({
      'holdDays': int.tryParse(_holdDaysCtrl.text) ?? 7,
      'minWithdrawAmount': double.tryParse(_minWithdrawCtrl.text) ?? 1000,
      'maxPromoDiscountPercent':
          double.tryParse(_maxPromoDiscountCtrl.text) ?? 20,
      'maintenanceMode': _maintenanceMode,
      'registrationOpen': _registrationOpen,
      'sellerRegistrationOpen': _sellerRegistrationOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton.icon(
                      onPressed: _saveAll,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Сохранить'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary),
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
                  // ── Ценовые пороги ────────────────────────────────────
                  _SectionHeader(
                      title: 'Пороги маржи по диапазонам цен',
                      icon: Icons.price_change_outlined),
                  const SizedBox(height: 8),
                  _buildTiersHint(),
                  const SizedBox(height: 12),
                  _buildTiersSection(),
                  const SizedBox(height: 20),

                  // ── Финансовые настройки ──────────────────────────────
                  _SectionHeader(
                      title: 'Финансы',
                      icon: Icons.account_balance_wallet_rounded),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
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

                  // ── Промокоды ─────────────────────────────────────────
                  _SectionHeader(
                      title: 'Промокоды',
                      icon: Icons.local_offer_rounded),
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

                  // ── Доступ ────────────────────────────────────────────
                  _SectionHeader(
                      title: 'Доступ', icon: Icons.security_rounded),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SwitchRow(
                        label: 'Регистрация покупателей',
                        subtitle:
                            'Разрешить новым пользователям регистрироваться',
                        value: _registrationOpen,
                        onChanged: (v) =>
                            setState(() => _registrationOpen = v),
                        activeColor: Colors.green,
                      ),
                      const Divider(height: 24),
                      _SwitchRow(
                        label: 'Регистрация продавцов',
                        subtitle:
                            'Разрешить новым продавцам подавать заявки',
                        value: _sellerRegistrationOpen,
                        onChanged: (v) =>
                            setState(() => _sellerRegistrationOpen = v),
                        activeColor: Colors.blue,
                      ),
                      const Divider(height: 24),
                      _SwitchRow(
                        label: 'Режим обслуживания',
                        subtitle:
                            'Приложение будет недоступно для пользователей',
                        value: _maintenanceMode,
                        onChanged: (v) =>
                            setState(() => _maintenanceMode = v),
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Активные промокоды ────────────────────────────────
                  _SectionHeader(
                      title: 'Активные промокоды',
                      icon: Icons.confirmation_number_rounded),
                  const SizedBox(height: 12),
                  _PromoCodesSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Секция ценовых порогов
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTiersHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Для каждого ценового диапазона задайте минимальный % маржи '
              'от розничной цены. Продавец не сможет добавить товар, '
              'если маржа ниже порога.',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiersSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Заголовок таблицы
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Диапазон (₸)',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Мин. маржа',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                ),
                const SizedBox(width: 40), // место для кнопки удаления
              ],
            ),
          ),
          const Divider(height: 1),

          // Строки порогов
          ..._tiers.asMap().entries.map((entry) {
            final i = entry.key;
            final tier = entry.value;
            return _TierRow(
              tier: tier,
              index: i,
              totalCount: _tiers.length,
              onChanged: (updated) {
                setState(() {
                  _tiers[i] = updated;
                  _tiersDirty = true;
                });
              },
              onDelete: () {
                setState(() {
                  _tiers.removeAt(i);
                  _tiersDirty = true;
                });
              },
            );
          }),

          // Кнопка добавить диапазон
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: _addTier,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить диапазон'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTier() {
    // Определяем разумную нижнюю границу нового диапазона
    final lastFinite = _tiers
        .where((t) => t.maxPrice != double.infinity)
        .toList()
      ..sort((a, b) => a.maxPrice.compareTo(b.maxPrice));

    final newMax = lastFinite.isNotEmpty
        ? lastFinite.last.maxPrice + 50000
        : 20000.0;

    setState(() {
      // Убираем "бесконечный" диапазон, если он есть — добавим его в конце
      final hasInfinity = _tiers.any((t) => t.maxPrice == double.infinity);
      if (hasInfinity) {
        _tiers.removeWhere((t) => t.maxPrice == double.infinity);
      }
      _tiers.add(PricingTier(maxPrice: newMax, minMarginPercent: 10));
      if (hasInfinity) {
        _tiers.add(const PricingTier(
            maxPrice: double.infinity, minMarginPercent: 8));
      }
      _tiersDirty = true;
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Строка одного ценового порога
// ─────────────────────────────────────────────────────────────────────────────
class _TierRow extends StatefulWidget {
  final PricingTier tier;
  final int index;
  final int totalCount;
  final ValueChanged<PricingTier> onChanged;
  final VoidCallback onDelete;

  const _TierRow({
    required this.tier,
    required this.index,
    required this.totalCount,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_TierRow> createState() => _TierRowState();
}

class _TierRowState extends State<_TierRow> {
  late TextEditingController _maxCtrl;
  late TextEditingController _pctCtrl;
  bool _isInfinity = false;

  @override
  void initState() {
    super.initState();
    _isInfinity = widget.tier.maxPrice == double.infinity;
    _maxCtrl = TextEditingController(
      text: _isInfinity ? '' : widget.tier.maxPrice.toInt().toString(),
    );
    _pctCtrl = TextEditingController(
      text: widget.tier.minMarginPercent.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _maxCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final maxPrice =
        _isInfinity ? double.infinity : (double.tryParse(_maxCtrl.text) ?? 0);
    final pct = double.tryParse(_pctCtrl.text) ?? 0;
    widget.onChanged(
        PricingTier(maxPrice: maxPrice, minMarginPercent: pct));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.index > 0) const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Верхняя граница
              Expanded(
                flex: 3,
                child: _isInfinity
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Свыше',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic),
                        ),
                      )
                    : TextFormField(
                        controller: _maxCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'До...',
                          suffixText: '₸',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppTheme.primary, width: 2),
                          ),
                        ),
                        onChanged: (_) => _notify(),
                      ),
              ),
              const SizedBox(width: 8),

              // % маржи
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _pctCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: '%',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 4),

              // Кнопка удалить (не показываем, если это последний)
              SizedBox(
                width: 36,
                child: widget.totalCount > 1
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: widget.onDelete,
                        padding: EdgeInsets.zero,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Список активных промокодов
// ─────────────────────────────────────────────────────────────────────────────
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
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'wanghong')
                .snapshots(),
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

  Widget _buildPromoList(
      BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14)),
        child: Center(
            child: Text('Нет активных партнёров',
                style: TextStyle(color: AppTheme.textSecondary))),
      );
    }
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: docs.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final data = doc.data();
          final profilesRaw = data['profiles'];
          final profiles = (profilesRaw is Map)
              ? profilesRaw.cast<String, dynamic>()
              : <String, dynamic>{};
          final wanghongRaw = profiles['wanghong'];
          final wanghong = (wanghongRaw is Map)
              ? wanghongRaw.cast<String, dynamic>()
              : <String, dynamic>{};
          final buyerRaw = profiles['buyer'];
          final buyer = (buyerRaw is Map)
              ? buyerRaw.cast<String, dynamic>()
              : <String, dynamic>{};
          final promoCode = wanghong['promoCode']?.toString() ?? '-';
          final firstName = buyer['firstName']?.toString() ?? '';
          final lastName = buyer['lastName']?.toString() ?? '';
          final fullName = '$firstName $lastName'.trim();
          final phone = data['phone']?.toString() ?? '-';
          final totalSales =
              (wanghong['totalSales'] as num?)?.toInt() ?? 0;
          final isActive = wanghong['isActive'] != false;
          final wPct =
              ((wanghong['wanghongPercent'] as num?) ?? 30).toDouble();

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(promoCode,
                      style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
                title: Text(
                    fullName.isNotEmpty ? fullName : phone,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Продаж: $totalSales  •  Доля: ${wPct.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Активен' : 'Отключён',
                    style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                onTap: () => _togglePromoCode(
                    context, doc.id, promoCode, isActive),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _togglePromoCode(BuildContext context, String docId,
      String promoCode, bool currentlyActive) async {
    final action = currentlyActive ? 'отключить' : 'включить';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            '${currentlyActive ? "Отключить" : "Включить"} промокод?'),
        content: Text('Вы хотите $action промокод "$promoCode"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    currentlyActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white),
            child: Text(currentlyActive ? 'Отключить' : 'Включить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'profiles.wanghong.isActive': !currentlyActive});
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Переиспользуемые виджеты
// ─────────────────────────────────────────────────────────────────────────────

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
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.textPrimary)),
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
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(hint,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        SizedBox(
          width: 90,
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
            validator: (v) {
              final n =
                  isInt ? int.tryParse(v ?? '') : double.tryParse(v ?? '');
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
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
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
