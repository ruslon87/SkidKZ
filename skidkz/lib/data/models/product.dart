import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus { draft, pending, active, disabled }

ProductStatus productStatusFromString(String? v) {
  switch ((v ?? 'draft').toLowerCase()) {
    case 'pending':
      return ProductStatus.pending;
    case 'active':
      return ProductStatus.active;
    case 'disabled':
      return ProductStatus.disabled;
    case 'draft':
    default:
      return ProductStatus.draft;
  }
}

String productStatusToString(ProductStatus s) {
  return switch (s) {
    ProductStatus.draft => 'draft',
    ProductStatus.pending => 'pending',
    ProductStatus.active => 'active',
    ProductStatus.disabled => 'disabled',
  };
}

class ProductImage {
  final String url;
  final String path; // storage path
  final int sort;

  const ProductImage({
    required this.url,
    required this.path,
    required this.sort,
  });

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      url: (map['url'] ?? '') as String,
      path: (map['path'] ?? '') as String,
      sort: (map['sort'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'url': url,
        'path': path,
        'sort': sort,
      };
}

class Product {
  final String id;

  // ownership
  final String storeId;
  final String sellerUid;

  // display
  final String title;
  final String? description;
  final String? categoryId;
  final String? brand;
  final String? sku;
  final List<String> tags;

  // pricing (for margin)
  final int retailPrice; // customer price
  final int costPrice; // закуп/себестоимость
  final String currency;

  // media
  final List<ProductImage> images;
  final String? coverUrl;

  // flags
  final ProductStatus status;
  final bool isService;

  // timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.storeId,
    required this.sellerUid,
    required this.title,
    required this.retailPrice,
    required this.costPrice,
    this.currency = 'KZT',
    this.description,
    this.categoryId,
    this.brand,
    this.sku,
    this.tags = const [],
    this.images = const [],
    this.coverUrl,
    this.status = ProductStatus.draft,
    this.isService = false,
    this.createdAt,
    this.updatedAt,
  });

  int get margin => retailPrice - costPrice;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final imagesRaw = (data['images'] as List?)?.cast<dynamic>() ?? const [];
    final images = imagesRaw
        .whereType<Map>()
        .map((m) => ProductImage.fromMap(m.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));

    DateTime? tsToDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return Product(
      id: doc.id,
      storeId: (data['storeId'] ?? '') as String,
      sellerUid: (data['sellerUid'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      description: data['description'] as String?,
      categoryId: data['categoryId'] as String?,
      brand: data['brand'] as String?,
      sku: data['sku'] as String?,
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      retailPrice: (data['retailPrice'] ?? 0) as int,
      costPrice: (data['costPrice'] ?? 0) as int,
      currency: (data['currency'] ?? 'KZT') as String,
      images: images,
      coverUrl: data['coverUrl'] as String?,
      status: productStatusFromString(data['status'] as String?),
      isService: (data['isService'] ?? false) as bool,
      createdAt: tsToDt(data['createdAt']),
      updatedAt: tsToDt(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'storeId': storeId,
      'sellerUid': sellerUid,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'brand': brand,
      'sku': sku,
      'tags': tags,
      'retailPrice': retailPrice,
      'costPrice': costPrice,
      'currency': currency,
      'images': images.map((e) => e.toMap()).toList(),
      'coverUrl': coverUrl ?? (images.isNotEmpty ? images.first.url : null),
      'status': productStatusToString(status),
      'isService': isService,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }..removeWhere((k, v) => v == null);
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'brand': brand,
      'sku': sku,
      'tags': tags,
      'retailPrice': retailPrice,
      'costPrice': costPrice,
      'currency': currency,
      'images': images.map((e) => e.toMap()).toList(),
      'coverUrl': coverUrl ?? (images.isNotEmpty ? images.first.url : null),
      'status': productStatusToString(status),
      'isService': isService,
      'updatedAt': FieldValue.serverTimestamp(),
    }..removeWhere((k, v) => v == null);
  }
}
