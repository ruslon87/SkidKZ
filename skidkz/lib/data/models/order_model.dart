import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  created,     // создан (черновик/оформление)
  submitted,   // отправлен (покупатель подтвердил)
  paid,        // оплачен
  completed,   // выполнен
  cancelled,   // отменён
  refunded,    // возврат
}

OrderStatus orderStatusFromString(String? v) {
  switch ((v ?? 'created').toLowerCase()) {
    case 'submitted':
      return OrderStatus.submitted;
    case 'paid':
      return OrderStatus.paid;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'refunded':
      return OrderStatus.refunded;
    case 'created':
    default:
      return OrderStatus.created;
  }
}

String orderStatusToString(OrderStatus s) {
  return switch (s) {
    OrderStatus.created => 'created',
    OrderStatus.submitted => 'submitted',
    OrderStatus.paid => 'paid',
    OrderStatus.completed => 'completed',
    OrderStatus.cancelled => 'cancelled',
    OrderStatus.refunded => 'refunded',
  };
}

/// Снимок позиции заказа (не зависит от текущего товара в products/)
/// Это важно, чтобы правильно считать маржу/комиссию потом.
class OrderItem {
  final String productId;
  final String titleSnapshot;

  final int retailPriceSnapshot; // цена для покупателя на момент заказа
  final int costPriceSnapshot;   // себестоимость на момент заказа
  final int qty;

  final String? imageUrlSnapshot;

  const OrderItem({
    required this.productId,
    required this.titleSnapshot,
    required this.retailPriceSnapshot,
    required this.costPriceSnapshot,
    required this.qty,
    this.imageUrlSnapshot,
  });

  int get lineRetail => retailPriceSnapshot * qty;
  int get lineCost => costPriceSnapshot * qty;
  int get lineMargin => lineRetail - lineCost;

  factory OrderItem.fromMap(Map<String, dynamic> m) {
    return OrderItem(
      productId: (m['productId'] ?? '') as String,
      titleSnapshot: (m['titleSnapshot'] ?? '') as String,
      retailPriceSnapshot: (m['retailPriceSnapshot'] ?? 0) as int,
      costPriceSnapshot: (m['costPriceSnapshot'] ?? 0) as int,
      qty: (m['qty'] ?? 1) as int,
      imageUrlSnapshot: m['imageUrlSnapshot'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'titleSnapshot': titleSnapshot,
        'retailPriceSnapshot': retailPriceSnapshot,
        'costPriceSnapshot': costPriceSnapshot,
        'qty': qty,
        'imageUrlSnapshot': imageUrlSnapshot,
      }..removeWhere((k, v) => v == null);
}

class OrderModel {
  final String id;

  // ownership
  final String buyerUid;

  // store attribution (если заказ всегда относится к одному магазину)
  final String storeId;

  // items snapshot
  final List<OrderItem> items;

  // totals snapshot
  final int totalRetail; // сумма для покупателя
  final int totalCost;   // сумма себестоимости
  final int totalMargin; // retail - cost

  // promo attribution (важно для ванхунов)
  final String? promoCodeUpper;    // "AMIRA"
  final String? promoOwnerUid;     // uid ванхуна (дублируем для быстрых запросов)
  final int? commissionBpsSnapshot; // % комиссии ванхуна на момент заказа (в bps)
  final int? holdDaysSnapshot;     // холд на момент заказа

  // status
  final OrderStatus status;

  // timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.buyerUid,
    required this.storeId,
    required this.items,
    required this.totalRetail,
    required this.totalCost,
    required this.totalMargin,
    this.promoCodeUpper,
    this.promoOwnerUid,
    this.commissionBpsSnapshot,
    this.holdDaysSnapshot,
    this.status = OrderStatus.created,
    this.createdAt,
    this.updatedAt,
  });

  int get commissionAmount {
    final bps = commissionBpsSnapshot ?? 0;
    // Комиссия строго от маржи:
    // commission = margin * bps / 10000
    return (totalMargin * bps) ~/ 10000;
  }

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    DateTime? tsToDt(dynamic v) => v is Timestamp ? v.toDate() : null;

    final itemsRaw = (d['items'] as List?)?.cast<dynamic>() ?? const [];
    final items = itemsRaw
        .whereType<Map>()
        .map((m) => OrderItem.fromMap(m.cast<String, dynamic>()))
        .toList();

    return OrderModel(
      id: doc.id,
      buyerUid: (d['buyerUid'] ?? '') as String,
      storeId: (d['storeId'] ?? '') as String,
      items: items,
      totalRetail: (d['totalRetail'] ?? 0) as int,
      totalCost: (d['totalCost'] ?? 0) as int,
      totalMargin: (d['totalMargin'] ?? 0) as int,
      promoCodeUpper: d['promoCodeUpper'] as String?,
      promoOwnerUid: d['promoOwnerUid'] as String?,
      commissionBpsSnapshot: d['commissionBpsSnapshot'] as int?,
      holdDaysSnapshot: d['holdDaysSnapshot'] as int?,
      status: orderStatusFromString(d['status'] as String?),
      createdAt: tsToDt(d['createdAt']),
      updatedAt: tsToDt(d['updatedAt']),
    );
  }

  /// Создание заказа: totals вычисляй ДО записи (в UI/репозитории),
  /// чтобы order был самодостаточный.
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'buyerUid': buyerUid,
      'storeId': storeId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalRetail': totalRetail,
      'totalCost': totalCost,
      'totalMargin': totalMargin,
      'promoCodeUpper': promoCodeUpper,
      'promoOwnerUid': promoOwnerUid,
      'commissionBpsSnapshot': commissionBpsSnapshot,
      'holdDaysSnapshot': holdDaysSnapshot,
      'status': orderStatusToString(status),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }..removeWhere((k, v) => v == null);
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'status': orderStatusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Утилита: собрать totals из items
  static ({int totalRetail, int totalCost, int totalMargin}) calcTotals(List<OrderItem> items) {
    var retail = 0;
    var cost = 0;
    for (final it in items) {
      retail += it.lineRetail;
      cost += it.lineCost;
    }
    return (totalRetail: retail, totalCost: cost, totalMargin: retail - cost);
  }
}
