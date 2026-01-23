import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  final _sellerPriceController = TextEditingController();
  
  String _selectedCategory = 'Товары 📦';
  bool _isService = false;

  final List<String> _categories = [
    'Товары 📦', 'Обувь 👟', 'Электроника 📱', 'Красота 💄', 
    'Еда 🍔', 'Ремонт 🛠️', 'Авто 🛞', 'Обучение 🎓', 'Туризм ✈️', 'Недвижимость 🏠'
  ];

  @override
  void initState() {
    super.initState();
    _retailPriceController.addListener(_updateCalculations);
    _sellerPriceController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _retailPriceController.removeListener(_updateCalculations);
    _sellerPriceController.removeListener(_updateCalculations);
    super.dispose();
  }

  void _updateCalculations() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0;
    final sellerPrice = double.tryParse(_sellerPriceController.text) ?? 0;
    
    // Logic from prompt:
    // C = W + M.
    // Minimum margin M_min = 3% of R.
    // So C_min = W + 0.03*R.
    // Also C <= 0.95 * R.
    // So W + 0.03*R <= 0.95*R  =>  W <= 0.92*R.
    
    final minMargin = retailPrice * 0.03;
    final maxSellerPrice = retailPrice * 0.92;
    
    // We assume platform adds margin to hit a target or just minimum?
    // Let's set Customer Price (SkidKZ) to be competitive, e.g. 90% of R, 
    // or W + minMargin if that's higher.
    double calculatedSkidkzPrice = sellerPrice + minMargin;
    if (calculatedSkidkzPrice < retailPrice * 0.9) {
       calculatedSkidkzPrice = retailPrice * 0.9; // Try to target 10% discount
    }
    
    // Validation
    final isValidW = sellerPrice > 0 && sellerPrice <= maxSellerPrice;
    final isValidC = calculatedSkidkzPrice <= retailPrice * 0.95; 

    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Добавить предложение'),
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
            
            SwitchListTile(
              title: const Text('Это услуга?'),
              value: _isService,
              onChanged: (val) {
                setState(() {
                  _isService = val;
                  if (_isService && !_selectedCategory.contains('🛠️')) {
                    _selectedCategory = 'Ремонт 🛠️'; // Default service category
                  }
                });
              },
            ),
            
            const Gap(16),
            const Text('Категория:'),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
            ),
            const Gap(32),
            const Text('Ценообразование', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(16),
            
            TextField(
              controller: _retailPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Розничная цена (R)',
                suffixText: '₸',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const Gap(16),
             TextField(
              controller: _sellerPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Сколько вы хотите получать (W)',
                suffixText: '₸',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                errorText: !isValidW && retailPrice > 0 ? 'Максимум: ${currencyFormatter.format(maxSellerPrice)} (92% от R)' : null,
              ),
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
                  _buildPriceRow('Розничная цена (R)', retailPrice),
                  const Divider(),
                  _buildPriceRow('Цена SkidKZ (Для клиента)', calculatedSkidkzPrice, isBold: true, color: AppTheme.primary),
                  _buildPriceRow('Ваша выплата (W)', sellerPrice, color: Colors.green),
                  const Divider(),
                  if (!isValidC && retailPrice > 0)
                    const Text('Ошибка: Цена SkidKZ должна быть <= 95% от Розничной', style: TextStyle(color: Colors.red)),
                  if (retailPrice > 0)
                     Text('Маржа платформы скрыта от продавца', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (retailPrice > 0 && sellerPrice > 0 && isValidW && _nameController.text.isNotEmpty) 
                  ? () => _save(retailPrice, sellerPrice) 
                  : null,
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

  Widget _buildPriceRow(String label, double price, {bool isBold = false, Color? color}) {
    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            currencyFormatter.format(price),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _save(double retail, double seller) {
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      category: _selectedCategory,
      retailPrice: retail,
      sellerPrice: seller,
      status: ProductStatus.pending,
      isService: _isService,
    );

    ref.read(productsProvider.notifier).addProduct(product);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Предложение отправлено на модерацию')),
    );
  }
}