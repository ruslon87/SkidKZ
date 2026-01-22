import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _promoController = TextEditingController();
  bool _isUnlocked = false;
  String? _appliedPromo;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => products.first, // Fallback
    );

    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: Theme.of(context).textTheme.displaySmall),
                  const Gap(8),
                  Text(product.description, style: Theme.of(context).textTheme.bodyLarge),
                  const Gap(24),
                  
                  // Price Section
                  Text('Retail Price:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                  Text(
                    currencyFormatter.format(product.retailPrice),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Gap(24),

                  // Promo Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isUnlocked ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.secondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isUnlocked ? AppTheme.success : AppTheme.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isUnlocked ? 'SkidKZ Price Unlocked!' : 'Unlock SkidKZ Price',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _isUnlocked ? AppTheme.success : AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        if (!_isUnlocked) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promoController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Promo Code',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  ),
                                ),
                              ),
                              const Gap(8),
                              ElevatedButton(
                                onPressed: _applyPromo,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            currencyFormatter.format(product.skidkzPrice),
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'Promo applied: $_appliedPromo',
                            style: const TextStyle(color: AppTheme.success),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isUnlocked ? () => _buy(product) : null,
            child: Text(_isUnlocked ? 'Pay ${currencyFormatter.format(product.skidkzPrice)}' : 'Enter Promo to Buy'),
          ),
        ),
      ),
    );
  }

  void _applyPromo() {
    if (_promoController.text.trim().toUpperCase() == 'IVAN25') {
      setState(() {
        _isUnlocked = true;
        _appliedPromo = 'IVAN25';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid promo code. Try IVAN25')),
      );
    }
  }

  void _buy(Product product) async {
    // Simulate Payment WebView
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Simulation (Tarlan Pay)'),
        content: const Text('Simulate payment gateway behavior?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fail'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Success'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final order = Order(
        id: const Uuid().v4(),
        buyerId: ref.read(authProvider)!.id,
        sellerId: product.sellerId,
        product: product,
        amount: product.skidkzPrice,
        promoCode: _appliedPromo,
        status: OrderStatus.paid,
        createdAt: DateTime.now(),
        earningStatus: EarningStatus.hold,
      );

      ref.read(ordersProvider.notifier).addOrder(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        context.go('/buyer/orders');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Try again.')),
        );
      }
    }
  }
}
