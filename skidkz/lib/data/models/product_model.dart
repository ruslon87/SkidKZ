enum ProductType { goods, service }
enum ProductStatus { draft, pending, approved, rejected }

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double retailPrice;
  final double wholesalePrice;
  final double skidkzPrice;
  final ProductType type;
  final ProductStatus status;
  final String imageUrl;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.skidkzPrice,
    required this.type,
    required this.status,
    required this.imageUrl,
  });

  Product copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    double? retailPrice,
    double? wholesalePrice,
    double? skidkzPrice,
    ProductType? type,
    ProductStatus? status,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      skidkzPrice: skidkzPrice ?? this.skidkzPrice,
      type: type ?? this.type,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
