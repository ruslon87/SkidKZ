// lib/data/services/promo_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PromoService {
  static final _db = FirebaseFirestore.instance;

  /// Генерирует уникальный промокод на основе имени пользователя.
  /// Формат: SKID + первые буквы имени + случайные цифры (например: SKIDALI4827)
  static String _generateCode(String firstName, String lastName) {
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch % 10000;
    final prefix = (firstName.isNotEmpty ? firstName.substring(0, firstName.length.clamp(0, 3)) : 'USR').toUpperCase();
    return 'SKID$prefix$seed';
  }

  /// Получает или создает промокод для текущего пользователя.
  /// Если промокод уже есть — возвращает существующий.
  /// Если нет — генерирует новый уникальный и сохраняет.
  static Future<String> getOrCreatePromoCode({
    required String uid,
    required String firstName,
    required String lastName,
  }) async {
    final userDoc = _db.collection('users').doc(uid);
    final snap = await userDoc.get();
    final data = snap.data() ?? {};
    final wanghong = (data['profiles'] as Map?)?.cast<String, dynamic>()?['wanghong'] as Map<String, dynamic>? ?? {};
    
    // Если промокод уже есть — возвращаем его
    final existing = wanghong['promoCode']?.toString();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // Генерируем новый уникальный промокод
    String code = _generateCode(firstName, lastName);
    
    // Проверяем уникальность (до 5 попыток)
    for (int i = 0; i < 5; i++) {
      final exists = await _db
          .collection('users')
          .where('profiles.wanghong.promoCode', isEqualTo: code)
          .limit(1)
          .get();
      if (exists.docs.isEmpty) break;
      // Если занят — генерируем новый с другим seed
      await Future.delayed(const Duration(milliseconds: 10));
      code = _generateCode(firstName, lastName);
    }

    // Сохраняем промокод в профиль пользователя
    await userDoc.set({
      'profiles': {
        'wanghong': {
          'promoCode': code,
          'promoCreatedAt': FieldValue.serverTimestamp(),
          'totalSales': 0,
          'totalEarnings': 0.0,
          'pendingBalance': 0.0,
          'paidBalance': 0.0,
          'clickCount': 0,
        }
      }
    }, SetOptions(merge: true));

    // Также создаем запись в коллекции promoCodes для быстрого поиска
    await _db.collection('promoCodes').doc(code).set({
      'code': code,
      'ownerUid': uid,
      'ownerName': '$firstName $lastName'.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'usageCount': 0,
    });

    return code;
  }

  /// Активирует роль wanghong для пользователя
  static Future<void> activateWanghongRole({
    required String uid,
    required String firstName,
    required String lastName,
    required String kaspiPhone,
  }) async {
    final code = await getOrCreatePromoCode(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
    );

    await _db.collection('users').doc(uid).set({
      'roles': FieldValue.arrayUnion(['wanghong']),
      'profiles': {
        'wanghong': {
          'completed': true,
          'promoCode': code,
          'kaspiPhone': kaspiPhone,
          'activatedAt': FieldValue.serverTimestamp(),
          'totalSales': 0,
          'totalEarnings': 0.0,
          'pendingBalance': 0.0,
          'paidBalance': 0.0,
          'clickCount': 0,
        }
      }
    }, SetOptions(merge: true));
  }

  /// Применяет промокод при оформлении заказа — обновляет статистику партнера
  static Future<void> applyPromoCode({
    required String code,
    required double orderAmount,
    required double partnerEarning,
  }) async {
    final promoSnap = await _db.collection('promoCodes').doc(code.toUpperCase()).get();
    if (!promoSnap.exists) return;
    
    final ownerUid = promoSnap.data()?['ownerUid']?.toString();
    if (ownerUid == null) return;

    // Обновляем статистику партнера
    await _db.collection('users').doc(ownerUid).update({
      'profiles.wanghong.totalSales': FieldValue.increment(1),
      'profiles.wanghong.totalEarnings': FieldValue.increment(partnerEarning),
      'profiles.wanghong.pendingBalance': FieldValue.increment(partnerEarning),
    });

    // Обновляем счетчик использования промокода
    await _db.collection('promoCodes').doc(code.toUpperCase()).update({
      'usageCount': FieldValue.increment(1),
      'lastUsedAt': FieldValue.serverTimestamp(),
    });
  }
}
