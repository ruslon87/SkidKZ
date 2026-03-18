// lib/data/models/cart_item.dart

class CartItem {
  final String productId;
  final String title;
  final int retailPrice;
  final int margin;
  final int qty;
  final String? imageUrl;

  const CartItem({
    required this.productId,
    required this.title,
    required this.retailPrice,
    required this.margin,
    required this.qty,
    this.imageUrl,
  });

  int get totalPrice => retailPrice * qty;
  int get totalMargin => margin * qty;

  CartItem copyWith({
    String? productId,
    String? title,
    int? retailPrice,
    int? margin,
    int? qty,
    String? imageUrl,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      retailPrice: retailPrice ?? this.retailPrice,
      margin: margin ?? this.margin,
      qty: qty ?? this.qty,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      retailPrice: map['retailPrice'] ?? 0,
      margin: map['margin'] ?? 0,
      qty: map['qty'] ?? 1,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'retailPrice': retailPrice,
        'margin': margin,
        'qty': qty,
        'imageUrl': imageUrl,
      };
}
