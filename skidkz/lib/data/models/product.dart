// lib/data/models/product.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductImage {
  final String url;

  const ProductImage({required this.url});

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      url: (map['url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{'url': url};
}

class Product {
  final String id;

  final String title;

  /// Розничная цена (₸)
  final int retailPrice;

  /// Маржа (₸)
  final int margin;

  /// Активен/опубликован (для витрины)
  final bool isActive;

  /// Обложка (может быть null)
  final String? coverUrl;

  /// Галерея
  final List<ProductImage> images;

  const Product({
    required this.id,
    required this.title,
    required this.retailPrice,
    required this.margin,
    required this.isActive,
    required this.images,
    this.coverUrl,
  });

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _asBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static List<ProductImage> _imagesFrom(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => ProductImage.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const <ProductImage>[];
  }

  /// Используется в `ProductRepository`: `.map(Product.fromDoc)`
  static Product fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    // поддержка разных названий полей, чтобы не падать
    final title = (data['title'] ??
            data['name'] ??
            data['productName'] ??
            '')
        .toString()
        .trim();

    final retailPrice = _asInt(
      data['retailPrice'] ?? data['price'] ?? data['finalPrice'],
    );

    final margin = _asInt(data['margin'] ?? data['profit']);

    final isActive = _asBool(
      data['isActive'] ?? data['active'] ?? data['published'],
    );

    final coverUrlRaw = (data['coverUrl'] ?? data['cover'] ?? '').toString().trim();
    final coverUrl = coverUrlRaw.isEmpty ? null : coverUrlRaw;

    final images = _imagesFrom(data['images']);

    return Product(
      id: doc.id,
      title: title.isEmpty ? 'Без названия' : title,
      retailPrice: retailPrice,
      margin: margin,
      isActive: isActive,
      coverUrl: coverUrl,
      images: images,
    );
  }
}
