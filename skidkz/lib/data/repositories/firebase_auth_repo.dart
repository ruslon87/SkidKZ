import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:skidkz/data/models/user_model.dart';

class FirebaseAuthRepo {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  FirebaseAuthRepo(this._auth, this._db);

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  // Read profile from Firestore
  Future<AppUser?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  // Ensure user doc exists right after auth
  Future<void> ensureUserDoc({
    required String uid,
    required String phoneNumber,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    if (doc.exists) return;

    await ref.set({
      'phoneNumber': phoneNumber,
      'role': null, // not chosen yet
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setRole({
    required String uid,
    required UserRole role,
  }) async {
    await _db.collection('users').doc(uid).set({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setWanghongPayoutAndOffer({
    required String uid,
    required String kaspiPhone,
    required bool offerAccepted,
  }) async {
    await _db.collection('users').doc(uid).set({
      'kaspiPhone': kaspiPhone,
      'offerAccepted': offerAccepted,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
