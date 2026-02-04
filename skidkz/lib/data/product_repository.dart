import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/data/models/product.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository(FirebaseFirestore.instance));

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository(this._firestore);

  Future<List<Product>> fetchProducts({DocumentSnapshot? lastDocument, int limit = 20}) async {
    Query query = _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }
}
