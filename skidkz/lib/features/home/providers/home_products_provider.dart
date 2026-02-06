import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skidkz/core/router/app_router.dart'; // firestoreProvider
import 'package:skidkz/data/models/product.dart';
import 'package:skidkz/data/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return ProductRepository(db);
});

final activeProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchActiveProducts();
});
