import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCodeRepository {
  PromoCodeRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _promo => _db.collection('promo_codes');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  String normalizeCode(String input) {
    final code = input.trim().toUpperCase();
    final ok = RegExp(r'^[A-Z0-9_]{4,12}$').hasMatch(code);
    if (!ok) {
      throw FormatException('Код: 4–12 символов, латиница/цифры/_');
    }
    return code;
  }

  /// Claim unique promo code:
  /// - creates promo_codes/{CODE}
  /// - updates users/{uid}.profiles.wanghong fields
  ///
  /// commissionBps: 1500 == 15.00%
  Future<void> claimPromoCodeTx({
    required String wanghongUid,
    required String desiredCode,
    int commissionBps = 1500,
    int holdDays = 14,
  }) async {
    final codeUpper = normalizeCode(desiredCode);
    final promoRef = _promo.doc(codeUpper);
    final userRef = _users.doc(wanghongUid);

    await _db.runTransaction((tx) async {
      final promoSnap = await tx.get(promoRef);
      if (promoSnap.exists) {
        throw StateError('CODE_TAKEN');
      }

      // create unique index doc
      tx.set(promoRef, {
        'ownerUid': wanghongUid,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // update user profile fields (merge)
      tx.set(userRef, {
        'profiles': {
          'wanghong': {
            'promoCode': desiredCode.trim(),
            'promoCodeUpper': codeUpper,
            'commissionBps': commissionBps,
            'holdDays': holdDays,
            'status': 'approved', // или pending -> admin approve
          }
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Admin changes commission (slider)
  Future<void> setWanghongCommission({
    required String wanghongUid,
    required int commissionBps,
  }) async {
    await _users.doc(wanghongUid).set({
      'profiles': {
        'wanghong': {'commissionBps': commissionBps}
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
