import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store.dart';

class StoreRepository {
  StoreRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _stores => _db.collection('stores');

  /// MVP: storeId == sellerUid (самый простой канон)
  Future<Store> ensureStoreForSeller({
    required String sellerUid,
    int freeLimit = 10,
  }) async {
    final ref = _stores.doc(sellerUid);
    final snap = await ref.get();
    if (snap.exists) {
      return Store.fromDoc(snap);
    }

    final store = Store(id: sellerUid, ownerUid: sellerUid, productLimit: freeLimit);
    await ref.set(store.toCreate());
    return store;
  }

  Stream<Store?> watchStore(String storeId) {
    return _stores.doc(storeId).snapshots().map((s) {
      if (!s.exists) return null;
      return Store.fromDoc(s);
    });
  }
}
