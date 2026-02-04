import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _stores => _db.collection('stores');

  Stream<List<Product>> watchActiveProducts() {
    return _products
        .where('status', isEqualTo: 'active')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(Product.fromDoc).toList());
  }

  Stream<List<Product>> watchStoreProducts(String storeId) {
    return _products
        .where('storeId', isEqualTo: storeId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(Product.fromDoc).toList());
  }

  /// Creates product with store productLimit check and increments productsCount.
  ///
  /// MVP rule: storeId == sellerUid
  Future<String> createProductTx({
    required String storeId,
    required String sellerUid,
    required String title,
    required int retailPrice,
    required int costPrice,
    String currency = 'KZT',
    String? description,
    String? categoryId,
    String? brand,
    String? sku,
    List<String> tags = const [],
    bool isService = false,
  }) async {
    final newRef = _products.doc();

    await _db.runTransaction((tx) async {
      final storeRef = _stores.doc(storeId);
      final storeSnap = await tx.get(storeRef);

      if (!storeSnap.exists) {
        throw StateError('Store not found: $storeId');
      }

      final data = storeSnap.data() as Map<String, dynamic>;
      final int productLimit = (data['productLimit'] ?? 10) as int;
      final int productsCount = (data['productsCount'] ?? 0) as int;

      if (productsCount >= productLimit) {
        throw StateError('LIMIT_REACHED');
      }

      final product = Product(
        id: newRef.id,
        storeId: storeId,
        sellerUid: sellerUid,
        title: title,
        description: description,
        categoryId: categoryId,
        brand: brand,
        sku: sku,
        tags: tags,
        retailPrice: retailPrice,
        costPrice: costPrice,
        currency: currency,
        status: ProductStatus.pending, // лучше сразу pending -> admin approve -> active
        isService: isService,
        images: const [],
        coverUrl: null,
      );

      tx.set(newRef, product.toFirestoreCreate());
      tx.update(storeRef, {
        'productsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return newRef.id;
  }

  Future<void> updateProduct(String productId, Product updated) async {
    await _products.doc(productId).update(updated.toFirestoreUpdate());
  }

  Future<void> setStatus(String productId, ProductStatus status) async {
    await _products.doc(productId).update({
      'status': productStatusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes product and decrements store productsCount (best-effort).
  /// Если у товара есть изображения — удаление из Storage делай отдельным вызовом StorageService.
  Future<void> deleteProductTx({
    required String productId,
    required String storeId,
  }) async {
    final ref = _products.doc(productId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      tx.delete(ref);

      final storeRef = _stores.doc(storeId);
      tx.update(storeRef, {
        'productsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
