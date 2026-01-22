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
    return WalletState(balance: 45000.0, hold: 18000.0);
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

// --- MOCK DATABASE (Legacy/Helper) ---
// Useful if we need access to providers via ref in a class
final mockDatabaseProvider = Provider((ref) => MockDatabase(ref));

class MockDatabase {
  final Ref ref;
  MockDatabase(this.ref);
}