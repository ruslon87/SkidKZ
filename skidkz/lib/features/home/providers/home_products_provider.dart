// lib/features/home/providers/home_products_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skidkz/data/product_repository.dart';
import 'package:skidkz/data/models/product.dart';

/// Репозиторий товаров (Firestore)
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(FirebaseFirestore.instance);
});

/// Активные (опубликованные) товары для витрины покупателя
final activeProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchActiveProducts();
});
