import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  /// Uploads raw bytes to:
  /// stores/{storeId}/products/{productId}/images/{uuid}.jpg
  Future<({String url, String path})> uploadProductImageBytes({
    required String storeId,
    required String productId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final path = 'stores/$storeId/products/$productId/images/$fileName';

    final ref = _storage.ref(path);
    final meta = SettableMetadata(contentType: contentType);

    await ref.putData(bytes, meta);
    final url = await ref.getDownloadURL();

    return (url: url, path: path);
  }

  Future<void> deleteByPath(String path) async {
    await _storage.ref(path).delete();
  }
}
