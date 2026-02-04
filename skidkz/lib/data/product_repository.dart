import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/product.dart';

class ProductRepository {
  ProductRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');

  Stream<List<Product>> watchActiveProducts() {
    return _products
        .where('status', isEqualTo: 'active')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(Product.fromDoc).toList());
  }
}
