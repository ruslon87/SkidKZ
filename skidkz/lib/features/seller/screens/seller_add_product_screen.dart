// lib/features/seller/screens/seller_add_product_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product.dart';
import 'package:skidkz/data/services/pricing_service.dart';

class SellerAddProductScreen extends StatefulWidget {
  final String? productId; // null = создание, иначе редактирование по ID
  final Product? existingProduct; // передаётся при редактировании из роутера

  const SellerAddProductScreen(
      {super.key, this.productId, this.existingProduct});

  @override
  State<SellerAddProductScreen> createState() => _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends State<SellerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _retailPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();

  String _status = 'draft'; // новые товары идут на модерацию
  bool _loading = false;
  bool _isEdit = false;
  String? _editId;

  // Ценовые пороги, загруженные из Firestore
  List<PricingTier> _tiers = [];
  bool _tiersLoaded = false;

  // Результат валидации цен (обновляется при изменении полей)
  PricingValidationResult? _priceValidation;

  @override
  void initState() {
    super.initState();
    _loadTiers();

    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _isEdit = true;
      _editId = p.id;
      _titleCtrl.text = p.title;
      _descCtrl.text = p.description ?? '';
      _retailPriceCtrl.text = p.retailPrice.toString();
      _costPriceCtrl.text = p.costPrice.toString();
      _coverCtrl.text = p.coverUrl ?? '';
      _status = p.status ?? 'draft';
    } else if (widget.productId != null) {
      _isEdit = true;
      _editId = widget.productId;
      _loadProduct();
    }
  }

  Future<void> _loadTiers() async {
    final tiers = await PricingService.loadTiers();
    if (mounted) {
      setState(() {
        _tiers = tiers;
        _tiersLoaded = true;
        _validatePrices();
      });
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(_editId)
        .get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _titleCtrl.text = (data['title'] as String?) ?? '';
        _descCtrl.text = (data['description'] as String?) ?? '';
        _retailPriceCtrl.text =
            ((data['retailPrice'] as int?) ?? 0).toString();
        _costPriceCtrl.text = ((data['costPrice'] as int?) ?? 0).toString();
        _coverCtrl.text = (data['coverUrl'] as String?) ?? '';
        _status = (data['status'] as String?) ?? 'draft';
      });
      _validatePrices();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _validatePrices() {
    if (!_tiersLoaded) return;
    final retail = int.tryParse(_retailPriceCtrl.text.trim()) ?? 0;
    final cost = int.tryParse(_costPriceCtrl.text.trim()) ?? 0;
    if (retail == 0 && cost == 0) {
      setState(() => _priceValidation = null);
      return;
    }
    final result = PricingService.validate(
      costPrice: cost,
      retailPrice: retail,
      tiers: _tiers,
    );
    setState(() => _priceValidation = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Дополнительная проверка ценообразования
    if (_priceValidation != null && !_priceValidation!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_priceValidation!.errorMessage ?? 'Ошибка цен'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final retailPrice = int.tryParse(_retailPriceCtrl.text.trim()) ?? 0;
      final costPrice = int.tryParse(_costPriceCtrl.text.trim()) ?? 0;
      final margin = (retailPrice - costPrice).clamp(0, retailPrice);

      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'retailPrice': retailPrice,
        'costPrice': costPrice,
        'margin': margin,
        // Для обратной совместимости
        'price': retailPrice,
        'coverUrl': _coverCtrl.text.trim(),
        'status': _isEdit ? _status : 'pending', // новые — на модерацию
        'sellerUid': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit && _editId != null) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(_editId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Товар обновлён'
                : 'Товар отправлен на модерацию'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('products')
        .doc(_editId)
        .delete();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактировать товар' : 'Добавить товар'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading && _isEdit && widget.existingProduct == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Название ──────────────────────────────────────────
                  _buildField(
                    controller: _titleCtrl,
                    label: 'Название товара',
                    hint: 'Например: Кроссовки Nike Air Max',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Описание ──────────────────────────────────────────
                  _buildField(
                    controller: _descCtrl,
                    label: 'Описание',
                    hint: 'Подробное описание товара...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // ── Блок цен ──────────────────────────────────────────
                  _buildPriceSection(),
                  const SizedBox(height: 16),

                  // ── Фото ──────────────────────────────────────────────
                  _buildField(
                    controller: _coverCtrl,
                    label: 'Ссылка на фото (URL)',
                    hint: 'https://example.com/photo.jpg',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  if (_coverCtrl.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _coverCtrl.text,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: AppTheme.elevated,
                          child: Center(
                            child: Text('Не удалось загрузить фото',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Статус (только при редактировании) ────────────────
                  if (_isEdit) ...[
                    _buildStatusSection(),
                    const SizedBox(height: 16),
                  ],

                  // ── Кнопка сохранения ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : Text(
                              _isEdit
                                  ? 'Сохранить изменения'
                                  : 'Отправить на модерацию',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Блок ценообразования
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPriceSection() {
    final retail = int.tryParse(_retailPriceCtrl.text.trim()) ?? 0;
    final cost = int.tryParse(_costPriceCtrl.text.trim()) ?? 0;
    final margin = retail > cost ? retail - cost : 0;
    final marginPct = retail > 0 ? (margin / retail * 100) : 0.0;

    final validation = _priceValidation;
    final hasError = validation != null && !validation.isValid;
    final hasSuccess = validation != null && validation.isValid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? Colors.red.shade300
              : hasSuccess
                  ? Colors.green.shade300
                  : AppTheme.divider,
          width: hasError || hasSuccess ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.price_change_outlined,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ценообразование',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Укажите себестоимость и розничную цену. '
            'Маржа (разница) распределяется между платформой и партнёрами.',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Поля цен
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildField(
                  controller: _costPriceCtrl,
                  label: 'Себестоимость (₸)',
                  hint: '3000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите цену';
                    return null;
                  },
                  onChanged: (_) => _validatePrices(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _retailPriceCtrl,
                  label: 'Цена для покупателя (₸)',
                  hint: '5000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите цену';
                    return null;
                  },
                  onChanged: (_) => _validatePrices(),
                ),
              ),
            ],
          ),

          // Индикатор маржи
          if (retail > 0 && cost > 0) ...[
            const SizedBox(height: 12),
            _buildMarginIndicator(
              margin: margin,
              marginPct: marginPct,
              validation: validation,
            ),
          ],

          // Подсказка по минимальной марже
          if (_tiersLoaded && retail > 0) ...[
            const SizedBox(height: 8),
            Text(
              PricingService.marginHint(retail, _tiers),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarginIndicator({
    required int margin,
    required double marginPct,
    required PricingValidationResult? validation,
  }) {
    final isValid = validation?.isValid ?? false;
    final color = margin <= 0
        ? Colors.red
        : isValid
            ? Colors.green
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                margin <= 0
                    ? Icons.error_outline
                    : isValid
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Маржа: $margin ₸ (${marginPct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (validation != null && !validation.isValid && validation.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              validation.errorMessage!,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
          if (validation != null && validation.isValid) ...[
            const SizedBox(height: 4),
            Text(
              'Цены соответствуют требованиям платформы',
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Блок статуса
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Статус товара',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusChip(
                label: 'Активен',
                selected: _status == 'active',
                color: Colors.green,
                onTap: () => setState(() => _status = 'active'),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'Черновик',
                selected: _status == 'draft',
                color: Colors.grey,
                onTap: () => setState(() => _status = 'draft'),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'Архив',
                selected: _status == 'archived',
                color: Colors.orange,
                onTap: () => setState(() => _status = 'archived'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Вспомогательный виджет поля
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: (v) {
        setState(() {});
        onChanged?.call(v);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _retailPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Вспомогательный виджет чипа статуса
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : AppTheme.divider, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : AppTheme.textSecondary,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
