import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/models/user_model.dart';

// --- PRODUCTS PROVIDER ---
final productsProvider = NotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    return [
      Product(id: '1', title: 'Кроссовки Nike Air', categoryIcon: '👟', retailPrice: 100000, skidkzPrice: 85000, wholesalePrice: 75000, sellerId: 'seller1'),
      Product(id: '2', title: 'iPhone 15 Case', categoryIcon: '📱', retailPrice: 15000, skidkzPrice: 12000, wholesalePrice: 10000, sellerId: 'seller1'),
      Product(id: '3', title: 'Кофемашина', categoryIcon: '☕', retailPrice: 100000, skidkzPrice: 85000, wholesalePrice: 75000, sellerId: 'seller2'),
      Product(id: '4', title: 'Услуги сантехника', categoryIcon: '🛠️', retailPrice: 20000, skidkzPrice: 15000, wholesalePrice: 10000, sellerId: 'seller2', type: ProductType.service),
      Product(id: '5', title: 'Губная помада', categoryIcon: '💄', retailPrice: 8000, skidkzPrice: 6000, wholesalePrice: 4000, sellerId: 'seller1'),
      Product(id: '6', title: 'Бургер Сет', categoryIcon: '🍔', retailPrice: 5000, skidkzPrice: 4000, wholesalePrice: 3000, sellerId: 'seller2'),
      Product(id: '7', title: 'Зимние шины', categoryIcon: '🛞', retailPrice: 100000, skidkzPrice: 85000, wholesalePrice: 75000, sellerId: 'seller1'),
      Product(id: '8', title: 'Фитнес-трекер', categoryIcon: '⌚', retailPrice: 25000, skidkzPrice: 20000, wholesalePrice: 15000, sellerId: 'seller2'),
      Product(id: '9', title: 'Рюкзак городской', categoryIcon: '🎒', retailPrice: 18000, skidkzPrice: 14000, wholesalePrice: 10000, sellerId: 'seller1'),
      Product(id: '10', title: 'Набор инструментов', categoryIcon: '🔧', retailPrice: 45000, skidkzPrice: 38000, wholesalePrice: 30000, sellerId: 'seller2'),
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

// --- ORDERS PROVIDER ---
final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    return [];
  }

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

// --- MOCK DATABASE (Deprecated/Legacy support) ---
// Kept for simple constants or direct access if needed, but providers are preferred.
final mockDatabaseProvider = Provider((ref) => MockDatabase(ref));

class MockDatabase {
  final Ref ref;
  MockDatabase(this.ref);

  List<Order> get orders => ref.read(ordersProvider);
}

// --- AUTH PROVIDER ---
final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  void login(UserRole role) {
    state = User(
      id: 'user_${role.name}',
      name: _getNameForRole(role),
      phoneNumber: '+77001234567',
      role: role,
      promoCode: role == UserRole.wanghong ? 'IVAN25' : null,
    );
  }

  void logout() {
    state = null;
  }

  String _getNameForRole(UserRole role) {
    switch (role) {
      case UserRole.buyer: return 'Иван';
      case UserRole.wanghong: return 'Ванхун Алексей';
      case UserRole.seller: return 'Продавец #1';
      case UserRole.admin: return 'Администратор';
    }
  }
}

// --- WALLET PROVIDER ---
final walletProvider = NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

class WalletState {
  final double balance;
  final double hold;

  WalletState({required this.balance, required this.hold});
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    return WalletState(balance: 45000, hold: 18000);
  }

  void addEarnings(double amount, {bool isHold = true}) {
    if (isHold) {
      state = WalletState(balance: state.balance, hold: state.hold + amount);
    } else {
      state = WalletState(balance: state.balance + amount, hold: state.hold);
    }
  }

  void requestWithdrawal() {
    if (state.balance >= 1000) {
      state = WalletState(balance: 0, hold: state.hold); // Demo: Clear balance
    }
  }
}
