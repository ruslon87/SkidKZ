// lib/data/repositories/mock_database.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/models/user_model.dart';
import 'package:skidkz/data/repositories/firebase_auth_repo.dart';

//
// -------------------- PRODUCTS (MOCK) --------------------
//

final productsProvider =
    NotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    return [
      Product(
        id: '1',
        name: 'Кроссовки Nike Air',
        category: 'Обувь 👟',
        retailPrice: 100000.0,
        sellerPrice: 75000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
      Product(
        id: '2',
        name: 'iPhone 15 Case',
        category: 'Аксессуары 📱',
        retailPrice: 15000.0,
        sellerPrice: 10000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
      Product(
        id: '3',
        name: 'Кофемашина',
        category: 'Бытовая техника ☕',
        retailPrice: 100000.0,
        sellerPrice: 75000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
      Product(
        id: '4',
        name: 'Услуги сантехника',
        category: 'Ремонт 🛠️',
        retailPrice: 20000.0,
        sellerPrice: 10000.0,
        status: ProductStatus.approved,
        isService: true,
      ),
      Product(
        id: '5',
        name: 'Губная помада',
        category: 'Красота 💄',
        retailPrice: 8000.0,
        sellerPrice: 4000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
      Product(
        id: '6',
        name: 'Бургер Сет',
        category: 'Еда 🍔',
        retailPrice: 5000.0,
        sellerPrice: 3000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
      Product(
        id: '7',
        name: 'Зимние шины',
        category: 'Авто 🛞',
        retailPrice: 100000.0,
        sellerPrice: 75000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
      Product(
        id: '8',
        name: 'Фитнес-трекер',
        category: 'Электроника ⌚',
        retailPrice: 25000.0,
        sellerPrice: 15000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
      Product(
        id: '9',
        name: 'Рюкзак городской',
        category: 'Аксессуары 🎒',
        retailPrice: 18000.0,
        sellerPrice: 10000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
      Product(
        id: '10',
        name: 'Набор инструментов',
        category: 'Инструменты 🔧',
        retailPrice: 45000.0,
        sellerPrice: 30000.0,
        status: ProductStatus.approved,
        isService: false,
      ),
    ];
  }

  void addProduct(Product product) {
    state = [...state, product];
  }

  void updateProductStatus(String id, ProductStatus status) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(status: status) else p
    ];
  }
}

//
// -------------------- ORDERS (MOCK) --------------------
//

final ordersProvider =
    NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => [];

  void addOrder(Order order) {
    state = [...state, order];
  }

  void updateOrderStatus(String id, OrderStatus status) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: status) else o
    ];
  }
}

//
// -------------------- WALLET (MOCK, for Wanghong demo) --------------------
//

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

class WalletState {
  final double balance;
  final double hold;

  WalletState({required this.balance, required this.hold});

  WalletState copyWith({double? balance, double? hold}) {
    return WalletState(
      balance: balance ?? this.balance,
      hold: hold ?? this.hold,
    );
  }
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    // Demo values (can be changed)
    return WalletState(balance: 0.0, hold: 13500.0);
  }

  void addEarnings(double amount, {bool isHold = true}) {
    if (isHold) {
      state = state.copyWith(hold: state.hold + amount);
    } else {
      state = state.copyWith(balance: state.balance + amount);
    }
  }

  void requestWithdrawal() {
    if (state.balance >= 1000) {
      // Demo: clear balance
      state = state.copyWith(balance: 0.0);
    }
  }
}

//
// -------------------- FIREBASE AUTH + PROFILE --------------------
//

// Firebase singletons
final firebaseAuthProvider =
    Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Repo from Step 2
final firebaseAuthRepoProvider = Provider<FirebaseAuthRepo>((ref) {
  return FirebaseAuthRepo(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

// Firebase auth state
final firebaseUserProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(firebaseAuthRepoProvider).authStateChanges();
});

// Firestore profile for current user
final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  final fbUser = await ref.watch(firebaseUserProvider.future);
  if (fbUser == null) return null;

  final repo = ref.watch(firebaseAuthRepoProvider);

  // Ensure /users/{uid} exists
  await repo.ensureUserDoc(
    uid: fbUser.uid,
    phoneNumber: fbUser.phoneNumber ?? '',
  );

  return repo.getProfile(fbUser.uid);
});

// Small controller for UI actions (set role / logout / save wanghong payout)
final authControllerProvider =
    Provider<AuthController>((ref) => AuthController(ref));

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  Future<void> logout() async {
    await ref.read(firebaseAuthRepoProvider).signOut();
  }

  Future<void> setRole(UserRole role) async {
    final fbUser = await ref.read(firebaseUserProvider.future);
    if (fbUser == null) throw Exception('Not signed in');

    await ref.read(firebaseAuthRepoProvider).setRole(uid: fbUser.uid, role: role);
    ref.invalidate(currentUserProfileProvider);
  }

  Future<void> setWanghongData({
    required String kaspiPhone,
    required bool offerAccepted,
  }) async {
    final fbUser = await ref.read(firebaseUserProvider.future);
    if (fbUser == null) throw Exception('Not signed in');

    await ref.read(firebaseAuthRepoProvider).setWanghongPayoutAndOffer(
      uid: fbUser.uid,
      kaspiPhone: kaspiPhone,
      offerAccepted: offerAccepted,
    );

    ref.invalidate(currentUserProfileProvider);
  }
}

//
// -------------------- Legacy helper (optional) --------------------
//

final mockDatabaseProvider = Provider((ref) => MockDatabase(ref));

class MockDatabase {
  final Ref ref;
  MockDatabase(this.ref);
}
