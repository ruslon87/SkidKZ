import 'package:skidkz/data/models/product.dart';

enum OrderStatus { paid, processing, completed, cancelled }

class Order {
  final String id;
  final Product product;
  final String buyerPhone;
  final String? promoCode;
  final double customerPrice;
  final double sellerPayout;
  final double margin;
  final double wanghunEarning;
  final double platformEarning;
  final DateTime createdAt;
  final DateTime holdUntil;
  final OrderStatus status;

  Order({
    required this.id,
    required this.product,
    required this.buyerPhone,
    this.promoCode,
    required this.customerPrice,
    required this.sellerPayout,
    required this.margin,
    required this.wanghunEarning,
    required this.platformEarning,
    required this.createdAt,
    required this.holdUntil,
    required this.status,
  });

  Order copyWith({
    String? id,
    Product? product,
    String? buyerPhone,
    String? promoCode,
    double? customerPrice,
    double? sellerPayout,
    double? margin,
    double? wanghunEarning,
    double? platformEarning,
    DateTime? createdAt,
    DateTime? holdUntil,
    OrderStatus? status,
  }) {
    return Order(
      id: id ?? this.id,
      product: product ?? this.product,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      promoCode: promoCode ?? this.promoCode,
      customerPrice: customerPrice ?? this.customerPrice,
      sellerPayout: sellerPayout ?? this.sellerPayout,
      margin: margin ?? this.margin,
      wanghunEarning: wanghunEarning ?? this.wanghunEarning,
      platformEarning: platformEarning ?? this.platformEarning,
      createdAt: createdAt ?? this.createdAt,
      holdUntil: holdUntil ?? this.holdUntil,
      status: status ?? this.status,
    );
  }
}
