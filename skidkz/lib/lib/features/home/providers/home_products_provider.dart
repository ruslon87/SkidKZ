import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skidkz/data/product_repository.dart';
import 'package:skidkz/data/models/product.dart';
import 'package:skidkz/core/router/app_router.dart'; // там firestoreProvider

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return ProductRepository(db);
});

final activeProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchActiveProducts();
});
