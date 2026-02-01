import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final int price;
  final int? bonusPrice;
  final String? imageUrl;
  final bool isActive;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.price,
    this.bonusPrice,
    this.imageUrl,
    required this.isActive,
    this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      price: (data['price'] as num).toInt(),
      bonusPrice: (data['bonusPrice'] as num?)?.toInt(),
      imageUrl: data['imageUrl'] as String?,
      isActive: data['isActive'] ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
