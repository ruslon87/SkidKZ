// lib/data/models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductImage {
  final String url;
  const ProductImage({required this.url});

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(url: (map['url'] ?? '').toString());
  }

  Map<String, dynamic> toMap() => <String, dynamic>{'url': url};
}

class Product {
  final String id;
  final String title;

  /// Розничная цена (₸) — цена, которую видит покупатель на витрине
  final int retailPrice;

  /// Себестоимость / минимальная цена продавца (₸)
  /// Это нижний порог — продавец не готов продавать ниже этой суммы
  final int costPrice;

  /// Маржа (₸) = retailPrice - costPrice
  /// Распределяется между платформой и партнёром (Wanghong)
  final int margin;

  /// Статус: 'active' | 'draft' | 'archived' | 'pending' | 'rejected'
  final String? status;

  /// Обратная совместимость — вычисляется из status
  bool get isActive => status == 'active';

  /// Описание товара
  final String? description;

  /// Обложка (может быть null)
  final String? coverUrl;

  /// Галерея
  final List<ProductImage> images;

  /// UID продавца
  final String? sellerUid;

  /// Дата создания
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.title,
    required this.retailPrice,
    required this.margin,
    required this.images,
    this.costPrice = 0,
    this.status,
    this.description,
    this.coverUrl,
    this.sellerUid,
    this.createdAt,
  });

  /// Процент маржи от розничной цены
  double get marginPercent =>
      retailPrice > 0 ? (margin / retailPrice * 100) : 0.0;

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _asStatus(dynamic v) {
    if (v == null) return 'draft';
    if (v is bool) return v ? 'active' : 'draft';
    final s = v.toString().toLowerCase().trim();
    if (s == 'active' || s == 'true' || s == '1' || s == 'yes') return 'active';
    if (s == 'archived') return 'archived';
    if (s == 'pending') return 'pending';
    if (s == 'rejected') return 'rejected';
    return 'draft';
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

    final title = (data['title'] ??
            data['name'] ??
            data['productName'] ??
            '')
        .toString()
        .trim();

    final retailPrice = _asInt(
      data['retailPrice'] ?? data['price'] ?? data['finalPrice'],
    );
    final costPrice = _asInt(
      data['costPrice'] ?? data['sellerPrice'] ?? data['minPrice'],
    );
    // Если margin не задан явно — вычисляем из разницы цен
    final marginRaw = data['margin'] ?? data['profit'];
    final margin = marginRaw != null
        ? _asInt(marginRaw)
        : (retailPrice - costPrice).clamp(0, retailPrice);

    // Приоритет у поля 'status', fallback на isActive/active/published
    final statusRaw = data['status'] ??
        data['isActive'] ??
        data['active'] ??
        data['published'];
    final status = _asStatus(statusRaw);

    final coverUrlRaw =
        (data['coverUrl'] ?? data['cover'] ?? '').toString().trim();
    final coverUrl = coverUrlRaw.isEmpty ? null : coverUrlRaw;

    final description = (data['description'] as String?)?.trim();
    final images = _imagesFrom(data['images']);
    final sellerUid = data['sellerUid'] as String?;

    final createdAtTs = data['createdAt'];
    DateTime? createdAt;
    if (createdAtTs is Timestamp) {
      createdAt = createdAtTs.toDate();
    }

    return Product(
      id: doc.id,
      title: title.isEmpty ? 'Без названия' : title,
      retailPrice: retailPrice,
      costPrice: costPrice,
      margin: margin,
      status: status,
      description: description,
      coverUrl: coverUrl,
      images: images,
      sellerUid: sellerUid,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
        'title': title,
        'retailPrice': retailPrice,
        'costPrice': costPrice,
        'margin': margin,
        'status': status ?? 'draft',
        'description': description ?? '',
        'coverUrl': coverUrl ?? '',
        'images': images.map((e) => e.toMap()).toList(),
        'sellerUid': sellerUid ?? '',
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
