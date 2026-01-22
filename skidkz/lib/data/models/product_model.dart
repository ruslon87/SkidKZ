enum ProductStatus { draft, pending, approved, rejected }

class Product {
  final String id;
  final String name;
  final String category; // 'Товары' or 'Услуги' or specific category
  final double retailPrice;
  final double sellerPrice; // Desired payout (W)
  final ProductStatus status;
  final bool isService;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.retailPrice,
    required this.sellerPrice,
    this.status = ProductStatus.approved,
    required this.isService,
  });

  // Helper to calculate the customer price (SkidKZ price)
  double get skidkzPrice {
    double minMargin = retailPrice * 0.03;
    double calculatedPrice = sellerPrice + minMargin;
    
    // Also ensure it's not more than 95% of retail (if possible)
    if (calculatedPrice > retailPrice * 0.95) {
      return calculatedPrice; // Constraint conflict, but prioritize covering seller cost
    }
    // Otherwise, maybe give a bit more margin for Wanghun
    // Target: 90% of retail?
    double targetPrice = retailPrice * 0.9;
    if (targetPrice >= calculatedPrice) {
      return targetPrice;
    }
    return calculatedPrice;
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? retailPrice,
    double? sellerPrice,
    ProductStatus? status,
    bool? isService,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      retailPrice: retailPrice ?? this.retailPrice,
      sellerPrice: sellerPrice ?? this.sellerPrice,
      status: status ?? this.status,
      isService: isService ?? this.isService,
    );
  }
}