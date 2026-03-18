// lib/features/seller/screens/seller_add_product_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product.dart';

class SellerAddProductScreen extends StatefulWidget {
  final String? productId; // null = создание, иначе редактирование по ID
  final Product? existingProduct; // передаётся при редактировании из роутера

  const SellerAddProductScreen({super.key, this.productId, this.existingProduct});

  @override
  State<SellerAddProductScreen> createState() => _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends State<SellerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _marginCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  String _status = 'active';
  bool _loading = false;
  bool _isEdit = false;
  String? _editId;

  @override
  void initState() {
    super.initState();
    // Если передан объект Product напрямую — заполняем поля из него
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _isEdit = true;
      _editId = p.id;
      _titleCtrl.text = p.title;
      _descCtrl.text = p.description ?? '';
      _priceCtrl.text = p.retailPrice.toString();
      _marginCtrl.text = p.margin.toString();
      _coverCtrl.text = p.coverUrl ?? '';
      _status = p.status ?? 'active';
    } else if (widget.productId != null) {
      _isEdit = true;
      _editId = widget.productId;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(_editId)
        .get();
    final data = doc.data();
    if (data != null) {
      _titleCtrl.text = (data['title'] as String?) ?? '';
      _descCtrl.text = (data['description'] as String?) ?? '';
      _priceCtrl.text = ((data['retailPrice'] as int?) ?? 0).toString();
      _marginCtrl.text = ((data['margin'] as int?) ?? 0).toString();
      _coverCtrl.text = (data['coverUrl'] as String?) ?? '';
      _status = (data['status'] as String?) ?? 'active';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
      final margin = int.tryParse(_marginCtrl.text.trim()) ?? 0;
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'retailPrice': price,
        'margin': margin,
        'coverUrl': _coverCtrl.text.trim(),
        'status': _status,
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
            content: Text(_isEdit ? 'Товар обновлён' : 'Товар добавлен'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
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
                  _buildField(
                    controller: _titleCtrl,
                    label: 'Название товара',
                    hint: 'Например: Кроссовки Nike Air Max',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _descCtrl,
                    label: 'Описание',
                    hint: 'Подробное описание товара...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _priceCtrl,
                          label: 'Цена для покупателя (₸)',
                          hint: '5000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Введите цену' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _marginCtrl,
                          label: 'Маржа партнёру (₸)',
                          hint: '500',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Введите маржу' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _coverCtrl,
                    label: 'Ссылка на фото (URL)',
                    hint: 'https://example.com/photo.jpg',
                  ),
                  const SizedBox(height: 16),
                  // Превью фото
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
                                      color: AppTheme.textSecondary))),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Статус
                  Container(
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_isEdit ? 'Сохранить изменения' : 'Добавить товар',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: (_) => setState(() {}),
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
    _priceCtrl.dispose();
    _marginCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }
}

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
