// lib/features/buyer/providers/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/data/models/cart_item.dart';
import 'package:skidkz/data/models/product.dart';

class CartState {
  final List<CartItem> items;

  const CartState({required this.items});

  int get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalMargin => items.fold(0, (sum, item) => sum + item.totalMargin);
  int get itemCount => items.fold(0, (sum, item) => sum + item.qty);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState(items: []));

  void addItem(Product product, int quantity) {
    final existingIndex = state.items.indexWhere((item) => item.productId == product.id);

    if (existingIndex >= 0) {
      // Товар уже в корзине - увеличиваем количество
      final updatedItem = state.items[existingIndex].copyWith(
        qty: state.items[existingIndex].qty + quantity,
      );
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItem;
      state = state.copyWith(items: updatedItems);
    } else {
      // Новый товар - добавляем в корзину
      final cover = product.coverUrl ??
          (product.images.isNotEmpty ? product.images.first.url : null);

      final newItem = CartItem(
        productId: product.id,
        title: product.title,
        retailPrice: product.retailPrice,
        margin: product.margin,
        qty: quantity,
        imageUrl: cover,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void removeItem(String productId) {
    final updatedItems = state.items.where((item) => item.productId != productId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(qty: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = const CartState(items: []);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
