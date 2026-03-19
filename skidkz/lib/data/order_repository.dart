import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'models/order_model.dart';
import 'models/cart_item.dart';
import 'services/pricing_service.dart';
import 'services/notification_service.dart';

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
  ///   6. Отправляет push-уведомления продавцу и партнёру.
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
    double wPct = 0;

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

            wPct =
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

    // ── 3. Получаем данные магазина для уведомления продавцу ─────────────
    String? sellerUid;
    String storeName = 'Магазин';
    try {
      final storeSnap =
          await _db.collection('stores').doc(storeId).get();
      if (storeSnap.exists) {
        final sd = storeSnap.data() ?? {};
        sellerUid = sd['ownerUid']?.toString();
        storeName = sd['name']?.toString() ?? storeName;
      }
    } catch (_) {}

    // ── 4. Создаём документ заказа ────────────────────────────────────────
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
    final orderId = docRef.id;

    // ── 5. Начисляем вознаграждение партнёру ─────────────────────────────
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

    // ── 6. Push-уведомления ───────────────────────────────────────────────
    final totalStr =
        '${totals.totalRetail.toStringAsFixed(0)} ₸';
    final itemCount = orderItems.fold<int>(0, (s, i) => s + i.qty);

    // 6a. Продавцу — новый заказ
    if (sellerUid != null) {
      await NotificationService.sendToUser(
        targetUid: sellerUid,
        title: '🛒 Новый заказ',
        body: '$itemCount товар(а) на $totalStr из $storeName',
        data: {'route': '/seller/orders', 'orderId': orderId},
      );
    }

    // 6b. Партнёру — промокод сработал
    if (promoOwnerUid != null && wanghongEarning > 0) {
      await NotificationService.sendToUser(
        targetUid: promoOwnerUid,
        title: '💰 Промокод сработал!',
        body:
            'Начислено ${wanghongEarning.toStringAsFixed(0)} ₸ (${wPct.toStringAsFixed(0)}% от маржи)',
        data: {
          'route': '/wanghong/wallet',
          'orderId': orderId,
          'earning': wanghongEarning.toString(),
        },
      );
    }

    return orderId;
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

  /// Обновление статуса заказа с push-уведомлением покупателю.
  Future<void> updateOrderStatus(
      String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({
      'status': orderStatusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Отправляем уведомление покупателю о смене статуса
    try {
      final orderDoc = await _orders.doc(orderId).get();
      if (!orderDoc.exists) return;
      final data = orderDoc.data() ?? {};
      final buyerUid = data['buyerUid']?.toString();
      if (buyerUid == null) return;

      final (title, body) = _statusNotificationText(status);
      await NotificationService.sendToUser(
        targetUid: buyerUid,
        title: title,
        body: body,
        data: {'route': '/buyer/orders', 'orderId': orderId},
      );
    } catch (_) {}
  }

  /// Текст уведомления по статусу заказа.
  (String, String) _statusNotificationText(OrderStatus status) {
    switch (status) {
      case OrderStatus.submitted:
        return ('✅ Заказ подтверждён', 'Продавец принял ваш заказ');
      case OrderStatus.paid:
        return ('🚚 Заказ оплачен', 'Ваш заказ оплачен и передан продавцу');
      case OrderStatus.cancelled:
        return ('❌ Заказ отменён', 'К сожалению, заказ был отменён');
      case OrderStatus.completed:
        return ('🎉 Заказ выполнен', 'Спасибо за покупку в SkidKZ!');
      case OrderStatus.refunded:
        return ('💰 Возврат средств', 'Средства за заказ будут возвращены');
      default:
        return ('📋 Статус заказа изменён',
            'Проверьте детали в разделе «Мои заказы»');
    }
  }
}
