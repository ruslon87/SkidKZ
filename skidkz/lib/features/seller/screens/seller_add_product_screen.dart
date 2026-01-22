import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';

class SellerAddProductScreen extends ConsumerStatefulWidget {
  const SellerAddProductScreen({super.key});

  @override
  ConsumerState<SellerAddProductScreen> createState() => _SellerAddProductScreenState();
}

class _SellerAddProductScreenState extends ConsumerState<SellerAddProductScreen> {
  final _nameController = TextEditingController();
  final _retailPriceController = TextEditingController();
  String _selectedIcon = '📦';
  double _wholesalePercentage = 75; // 75% of retail

  final List<String> _icons = ['📦', '👟', '📱', '💄', '🍔', '🛠️', '🛞', '🎓', '✈️', '🏠'];

  @override
  Widget build(BuildContext context) {
    // Calculate prices based on inputs
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0;
    final wholesalePrice = retailPrice * (_wholesalePercentage / 100);
    final skidkzPrice = retailPrice * 0.85; // Fixed 15% discount for buyer? 
    // Prompt says: "Wholesale price <= Retail". "Min difference 10%".
    // "Economics (Demo): Retail 100k, SkidKZ 85k, Wholesale 75k".
    // So Wholesale is 75% of Retail. SkidKZ is 85% of Retail.
    // Margin = SkidKZ (85) - Wholesale (75) = 10k.
    
    // I will use slider to adjust Wholesale Price as % of Retail.
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Добавить товар'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Основная информация', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Название товара / услуги',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const Gap(16),
            const Text('Выберите категорию (иконку):'),
            const Gap(8),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final isSelected = icon == _selectedIcon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(32),
            const Text('Ценообразование', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(16),
            TextField(
              controller: _retailPriceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Розничная цена (₸)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const Gap(24),
            Text('Оптовая цена для SkidKZ: ${_formatPrice(wholesalePrice)} ₸'),
            const Gap(8),
            Row(
              children: [
                const Text('50%'),
                Expanded(
                  child: Slider(
                    value: _wholesalePercentage,
                    min: 50,
                    max: 90,
                    divisions: 40,
                    label: '${_wholesalePercentage.round()}%',
                    onChanged: (value) => setState(() => _wholesalePercentage = value),
                  ),
                ),
                const Text('90%'),
              ],
            ),
            Text(
              'Это ${_wholesalePercentage.round()}% от розничной цены',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Gap(24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Розничная цена', retailPrice),
                  const Divider(),
                  _buildPriceRow('Цена SkidKZ (Покупатель)', skidkzPrice, isBold: true),
                  _buildPriceRow('Оптовая цена (Вам)', wholesalePrice, color: Colors.green),
                  const Divider(),
                  _buildPriceRow('Маржа платформы', skidkzPrice - wholesalePrice, isSmall: true),
                ],
              ),
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: retailPrice > 0 && _nameController.text.isNotEmpty ? () => _save() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Отправить на модерацию', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double price, {bool isBold = false, Color? color, bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isSmall ? 12 : 14, color: isSmall ? Colors.grey : Colors.black)),
          Text(
            '${_formatPrice(price)} ₸',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
              fontSize: isSmall ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0;
    final wholesalePrice = retailPrice * (_wholesalePercentage / 100);
    final skidkzPrice = retailPrice * 0.85;

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      categoryIcon: _selectedIcon,
      retailPrice: retailPrice.toInt(),
      skidkzPrice: skidkzPrice.toInt(),
      sellerId: 'seller1',
    );

    ref.read(mockDatabaseProvider).addProduct(product);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Товар отправлен на модерацию')),
    );
  }

  String _formatPrice(num price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }
}
