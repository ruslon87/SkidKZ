// lib/features/buyer/providers/favorites_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/data/models/product.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _loadFromFirestore();
  }

  void _loadFromFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;
      final favs = (data['favorites'] as List?)?.cast<String>() ?? [];
      state = favs.toSet();
    });
  }

  Future<void> toggle(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newState = Set<String>.from(state);
    if (newState.contains(productId)) {
      newState.remove(productId);
    } else {
      newState.add(productId);
    }
    state = newState;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'favorites': newState.toList()},
      SetOptions(merge: true),
    );
  }

  bool isFavorite(String productId) => state.contains(productId);
}

final favoriteProductsProvider = StreamProvider<List<Product>>((ref) {
  final favoriteIds = ref.watch(favoritesProvider);
  if (favoriteIds.isEmpty) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('products')
      .where(FieldPath.documentId, whereIn: favoriteIds.toList())
      .snapshots()
      .map((q) => q.docs.map(Product.fromDoc).toList());
});
