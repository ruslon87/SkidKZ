// lib/features/buyer/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product.dart';
import 'package:skidkz/features/buyer/providers/cart_provider.dart';
import 'package:skidkz/features/buyer/providers/favorites_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  int _selectedImageIndex = 0;

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

  void _addToCart() {
    ref.read(cartProvider.notifier).addItem(widget.product, _qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} добавлен в корзину'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Корзина',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _shareProduct() {
    final text = '🛘 ${widget.product.title}\n'
        '💰 Цена: ${_formatMoney(widget.product.retailPrice)}\n'
        '📲 Скачай SkidKZ и покупай выгодно!\n'
        'https://skidkz.kz/product/${widget.product.id}';
    Share.share(text, subject: widget.product.title);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isFav = ref.watch(favoritesProvider).contains(product.id);
    final allImages = [
      if (product.coverUrl != null && product.coverUrl!.isNotEmpty) product.coverUrl!,
      ...product.images.map((e) => e.url).where((u) => u.isNotEmpty),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: Text(product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : AppTheme.textSecondary),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(product.id),
          ),
          IconButton(
            icon: Icon(Icons.share, color: AppTheme.textSecondary),
            onPressed: _shareProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Галерея изображений
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Container(
                      color: AppTheme.elevated,
                      child: allImages.isEmpty
                          ? Icon(Icons.image_outlined,
                              size: 80, color: AppTheme.textDisabled)
                          : Stack(
                              children: [
                                PageView.builder(
                                  itemCount: allImages.length,
                                  onPageChanged: (i) =>
                                      setState(() => _selectedImageIndex = i),
                                  itemBuilder: (context, i) => Image.network(
                                    allImages[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.broken_image_outlined,
                                        color: AppTheme.textDisabled),
                                  ),
                                ),
                                if (allImages.length > 1)
                                  Positioned(
                                    bottom: 12,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        allImages.length,
                                        (i) => Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          width: _selectedImageIndex == i ? 20 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _selectedImageIndex == i
                                                ? AppTheme.primary
                                                : Colors.white.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.title,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(_formatMoney(product.retailPrice),
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+ ${_formatMoney(product.margin)} партнёру',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        if (product.description != null &&
                            product.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Описание',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 8),
                          Text(product.description!,
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  height: 1.5)),
                        ],
                        const SizedBox(height: 24),
                        // Выбор количества
                        Row(
                          children: [
                            Text('Количество:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.divider),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _qty > 1
                                        ? () => setState(() => _qty--)
                                        : null,
                                  ),
                                  Text('$_qty',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () => setState(() => _qty++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Итого: ${_formatMoney(product.retailPrice * _qty)}',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Нижняя панель
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareProduct,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Поделиться'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: const Text('В корзину'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
