import 'package:skidkz/data/models/product_model.dart';

enum OrderStatus { paid, awaitingFulfillment, fulfilled, completed, cancelled }
enum EarningStatus { hold, available, paidOut, blocked }

class Order {
  final String id;
  final String buyerId;
  final String sellerId; // Simplified: 1 order = 1 product for MVP
  final Product product;
  final double amount;
  final String? promoCode;
  final OrderStatus status;
  final DateTime createdAt;
  
  // For Wanghong earnings
  final EarningStatus earningStatus;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.product,
    required this.amount,
    this.promoCode,
    required this.status,
    required this.createdAt,
    this.earningStatus = EarningStatus.hold,
  });

  Order copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    Product? product,
    double? amount,
    String? promoCode,
    OrderStatus? status,
    DateTime? createdAt,
    EarningStatus? earningStatus,
  }) {
    return Order(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      product: product ?? this.product,
      amount: amount ?? this.amount,
      promoCode: promoCode ?? this.promoCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      earningStatus: earningStatus ?? this.earningStatus,
    );
  }
}
