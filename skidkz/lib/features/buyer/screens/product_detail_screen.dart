// lib/features/buyer/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product.dart';
import 'package:skidkz/features/buyer/providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    required this.product,
    super.key,
  });

  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  void _incrementQuantity() {
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _addToCart() {
    final cartNotifier = ref.read(cartProvider.notifier);
    cartNotifier.addItem(widget.product, _quantity);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Добавлено в корзину: ${_quantity} шт.'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Опционально: вернуться на главную страницу
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) context.pop();
    });
  }

  String _formatMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(' ');
    }
    return '${buf.toString()} ₸';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cover = product.coverUrl ??
        (product.images.isNotEmpty ? product.images.first.url : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товар'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение товара
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 300,
                color: AppTheme.elevated,
                child: cover == null || cover.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: AppTheme.textDisabled,
                        ),
                      )
                    : Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 80,
                            color: AppTheme.textDisabled,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Название товара
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            // Цена и маржа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Цена',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMoney(product.retailPrice),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Маржа',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMoney(product.margin),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Галерея изображений (если есть)
            if (product.images.isNotEmpty) ...[
              Text(
                'Галерея',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: product.images.length,
                  itemBuilder: (context, index) {
                    final image = product.images[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          color: AppTheme.elevated,
                          child: Image.network(
                            image.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: AppTheme.textDisabled,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Количество товара
            Text(
              'Количество',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decrementQuantity,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _quantity.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _incrementQuantity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Кнопка "В корзину"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Добавить в корзину',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
