import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'models/order_model.dart';
import 'models/cart_item.dart';
import 'services/pricing_service.dart';

class OrderRepository {
  OrderRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Создание заказа из товаров в корзине.
  ///
  /// Если передан [promoCode], репозиторий:
  ///   1. Ищет владельца промокода в Firestore.
  ///   2. Читает его [wanghongPercent].
  ///   3. Рассчитывает распределение маржи через [PricingService.splitMargin].
  ///   4. Начисляет вознаграждение партнёру (pendingBalance).
  ///   5. Сохраняет снимок комиссии в заказе.
  Future<String> createOrder({
    required List<CartItem> items,
    required String storeId,
    String? promoCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // ── 1. Преобразуем CartItem → OrderItem ──────────────────────────────
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

    final totals = OrderModel.calcTotals(orderItems);

    // ── 2. Промокод: ищем владельца и его % ──────────────────────────────
    String? promoCodeUpper;
    String? promoOwnerUid;
    int? commissionBpsSnapshot;
    double wanghongEarning = 0;

    if (promoCode != null && promoCode.trim().isNotEmpty) {
      promoCodeUpper = promoCode.trim().toUpperCase();

      // Ищем промокод в коллекции promoCodes
      final promoSnap = await _db
          .collection('promoCodes')
          .doc(promoCodeUpper)
          .get();

      if (promoSnap.exists) {
        final promoData = promoSnap.data() ?? {};
        final isActive = promoData['isActive'] != false;

        if (isActive) {
          promoOwnerUid = promoData['ownerUid']?.toString();

          if (promoOwnerUid != null) {
            // Читаем wanghongPercent из профиля партнёра
            final ownerSnap = await _db
                .collection('users')
                .doc(promoOwnerUid)
                .get();
            final ownerData = ownerSnap.data() ?? {};
            final profilesRaw = ownerData['profiles'];
            final profiles = (profilesRaw is Map)
                ? profilesRaw.cast<String, dynamic>()
                : <String, dynamic>{};
            final wanghongRaw = profiles['wanghong'];
            final wanghong = (wanghongRaw is Map)
                ? wanghongRaw.cast<String, dynamic>()
                : <String, dynamic>{};

            final wPct =
                ((wanghong['wanghongPercent'] as num?) ?? 30.0).toDouble();

            // Рассчитываем распределение маржи
            final split = PricingService.splitMargin(
              margin: totals.totalMargin,
              wanghongPercent: wPct,
            );
            wanghongEarning = split.wanghongAmount;

            // Сохраняем в bps (basis points) для совместимости с OrderModel
            commissionBpsSnapshot = (wPct * 100).round(); // % → bps
          }
        }
      }
    }

    // ── 3. Создаём документ заказа ────────────────────────────────────────
    final order = OrderModel(
      id: '',
      buyerUid: user.uid,
      storeId: storeId,
      items: orderItems,
      totalRetail: totals.totalRetail,
      totalCost: totals.totalCost,
      totalMargin: totals.totalMargin,
      promoCodeUpper: promoCodeUpper,
      promoOwnerUid: promoOwnerUid,
      commissionBpsSnapshot: commissionBpsSnapshot,
      status: OrderStatus.created,
    );

    final docRef = await _orders.add(order.toFirestoreCreate());

    // ── 4. Начисляем вознаграждение партнёру ─────────────────────────────
    if (promoOwnerUid != null && wanghongEarning > 0) {
      await Future.wait([
        // Обновляем статистику пользователя
        _db.collection('users').doc(promoOwnerUid).update({
          'profiles.wanghong.totalSales': FieldValue.increment(1),
          'profiles.wanghong.totalEarnings':
              FieldValue.increment(wanghongEarning),
          'profiles.wanghong.pendingBalance':
              FieldValue.increment(wanghongEarning),
        }),
        // Обновляем счётчик промокода
        _db.collection('promoCodes').doc(promoCodeUpper).update({
          'usageCount': FieldValue.increment(1),
          'lastUsedAt': FieldValue.serverTimestamp(),
        }),
      ]);
    }

    return docRef.id;
  }

  /// Получение заказов текущего пользователя (стрим).
  Stream<List<OrderModel>> watchUserOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _orders
        .where('buyerUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(OrderModel.fromDoc).toList());
  }

  /// Получение одного заказа по ID.
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromDoc(
        doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  /// Обновление статуса заказа.
  Future<void> updateOrderStatus(
      String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({
      'status': orderStatusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
