import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'models/order_model.dart';
import 'models/cart_item.dart';

class OrderRepository {
  OrderRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  /// Создание заказа из товаров в корзине
  Future<String> createOrder({
    required List<CartItem> items,
    required String storeId,
    String? promoCode,
    String? promoOwnerUid,
    int? commissionBps,
    int? holdDays,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Преобразуем CartItem в OrderItem
    final orderItems = items
        .map((item) => OrderItem(
              productId: item.productId,
              titleSnapshot: item.title,
              retailPriceSnapshot: item.retailPrice,
              costPriceSnapshot: item.retailPrice - item.margin,
              qty: item.qty,
              imageUrlSnapshot: item.imageUrl,
            ))
        .toList();

    // Вычисляем итоги
    final totals = OrderModel.calcTotals(orderItems);

    // Создаем заказ
    final order = OrderModel(
      id: '', // будет установлен при сохранении
      buyerUid: user.uid,
      storeId: storeId,
      items: orderItems,
      totalRetail: totals.totalRetail,
      totalCost: totals.totalCost,
      totalMargin: totals.totalMargin,
      promoCodeUpper: promoCode?.toUpperCase(),
      promoOwnerUid: promoOwnerUid,
      commissionBpsSnapshot: commissionBps,
      holdDaysSnapshot: holdDays,
      status: OrderStatus.created,
    );

    // Сохраняем в Firestore
    final docRef = await _orders.add(order.toFirestoreCreate());
    return docRef.id;
  }

  /// Получение заказов пользователя
  Stream<List<OrderModel>> watchUserOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _orders
        .where('buyerUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(OrderModel.fromDoc).toList());
  }

  /// Получение одного заказа
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  /// Обновление статуса заказа
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({
      'status': orderStatusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
