enum ProductType { goods, service }
enum ProductStatus { draft, pending, approved, rejected }

class Product {
  final String id;
  final String sellerId;
  final String name; // Renamed from title
  final String description;
  final String categoryIcon; // Replaces imageUrl
  final int retailPrice;
  final int wholesalePrice;
  final int skidkzPrice;
  final ProductType type;
  final ProductStatus status;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description = '',
    required this.categoryIcon,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.skidkzPrice,
    this.type = ProductType.goods,
    this.status = ProductStatus.approved,
  });

  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    String? categoryIcon,
    int? retailPrice,
    int? wholesalePrice,
    int? skidkzPrice,
    ProductType? type,
    ProductStatus? status,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      skidkzPrice: skidkzPrice ?? this.skidkzPrice,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}
