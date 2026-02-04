import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id; // storeId
  final String ownerUid;

  final String plan; // free | pro
  final int productLimit; // free: 10
  final int productsCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Store({
    required this.id,
    required this.ownerUid,
    this.plan = 'free',
    this.productLimit = 10,
    this.productsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Store.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    DateTime? tsToDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return Store(
      id: doc.id,
      ownerUid: (d['ownerUid'] ?? '') as String,
      plan: (d['plan'] ?? 'free') as String,
      productLimit: (d['productLimit'] ?? 10) as int,
      productsCount: (d['productsCount'] ?? 0) as int,
      createdAt: tsToDt(d['createdAt']),
      updatedAt: tsToDt(d['updatedAt']),
    );
  }

  Map<String, dynamic> toCreate() => {
        'ownerUid': ownerUid,
        'plan': plan,
        'productLimit': productLimit,
        'productsCount': productsCount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toUpdate() => {
        'plan': plan,
        'productLimit': productLimit,
        'productsCount': productsCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
