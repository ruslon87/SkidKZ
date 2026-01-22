import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/repositories/mock_database.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';

class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final products = ref.watch(productsProvider)
        .where((p) => p.sellerId == user?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context, ref, user!.id),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: products.isEmpty
          ? const Center(child: Text('No products yet. Add one!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _SellerProductCard(product: products[index]);
              },
            ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, String sellerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddProductForm(sellerId: sellerId),
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  final Product product;

  const _SellerProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title, style: Theme.of(context).textTheme.titleMedium),
                      const Gap(4),
                      Text(
                        'Retail: ${currencyFormatter.format(product.retailPrice)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'SkidKZ: ${currencyFormatter.format(product.skidkzPrice)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: product.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProductStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case ProductStatus.draft:
        color = Colors.grey;
        text = 'Draft';
        break;
      case ProductStatus.pending:
        color = Colors.orange;
        text = 'Moderation';
        break;
      case ProductStatus.approved:
        color = AppTheme.success;
        text = 'Approved';
        break;
      case ProductStatus.rejected:
        color = AppTheme.error;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AddProductForm extends ConsumerStatefulWidget {
  final String sellerId;

  const _AddProductForm({required this.sellerId});

  @override
  ConsumerState<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends ConsumerState<_AddProductForm> {
  final _titleController = TextEditingController();
  final _retailPriceController = TextEditingController();
  double _discount = 15.0;
  ProductType _type = ProductType.goods;

  @override
  Widget build(BuildContext context) {
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0;
    final wholesalePrice = retailPrice * (1 - (_discount + 10) / 100); // Mock formula
    final skidkzPrice = retailPrice * (1 - _discount / 100);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add New Product', style: Theme.of(context).textTheme.headlineSmall),
            const Gap(24),
            DropdownButtonFormField<ProductType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: ProductType.goods, child: Text('Goods')),
                DropdownMenuItem(value: ProductType.service, child: Text('Service')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const Gap(16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const Gap(16),
            TextField(
              controller: _retailPriceController,
              decoration: const InputDecoration(labelText: 'Retail Price (Real Store Price)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const Gap(24),
            Text('Wholesale Discount: ${_discount.round()}%'),
            Slider(
              value: _discount,
              min: 5,
              max: 50,
              divisions: 9,
              label: '${_discount.round()}%',
              onChanged: (v) => setState(() => _discount = v),
            ),
            const Gap(16),
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _PriceRow(label: 'Retail Price', value: retailPrice, isCrossed: true),
                    _PriceRow(label: 'Wholesale (Hidden)', value: wholesalePrice),
                    const Divider(),
                    _PriceRow(label: 'SkidKZ Price', value: skidkzPrice, isBold: true, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: () {
                final product = Product(
                  id: const Uuid().v4(),
                  sellerId: widget.sellerId,
                  title: _titleController.text,
                  description: 'New product description',
                  retailPrice: retailPrice,
                  wholesalePrice: wholesalePrice,
                  skidkzPrice: skidkzPrice,
                  type: _type,
                  status: ProductStatus.pending,
                  imageUrl: '',
                );
                ref.read(productsProvider.notifier).addProduct(product);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product submitted for moderation')),
                );
              },
              child: const Text('Submit for Moderation'),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final bool isCrossed;
  final Color? color;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isCrossed = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₸', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            currencyFormatter.format(value),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              decoration: isCrossed ? TextDecoration.lineThrough : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
