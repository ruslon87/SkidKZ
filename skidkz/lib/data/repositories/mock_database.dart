import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/models/user_model.dart';

final mockDatabaseProvider = Provider<MockDatabase>((ref) => MockDatabase());

class MockDatabase {
  // Hardcoded Economy
  static const int retailPrice = 100000;
  static const int skidkzPrice = 85000;
  static const int wholesalePrice = 75000;
  static const int margin = 10000;
  static const int wanghongCommission = 9000;
  static const int platformCommission = 1000;
  static const int minWithdrawal = 1000;

  // Mock Products
  final List<Product> _products = [
    Product(id: '1', name: 'Кроссовки Nike Air', categoryIcon: '👟', retailPrice: 100000, skidkzPrice: 85000, wholesalePrice: 75000, sellerId: 'seller1'),
    Product(id: '2', name: 'iPhone 15 Case', categoryIcon: '📱', retailPrice: 15000, skidkzPrice: 12000, wholesalePrice: 10000, sellerId: 'seller1'),
    Product(id: '3', name: 'Кофемашина', categoryIcon: '☕', retailPrice: 100000, skidkzPrice: 85000, wholesalePrice: 75000, sellerId: 'seller2'),
    Product(id: '4', name: 'Услуги сантехника', categoryIcon: '🛠️', retailPrice: 20000, skidkzPrice: 15000, wholesalePrice: 10000, sellerId: 'seller2', type: ProductType.service),
    Product(id: '5', name: 'Губная помада', categoryIcon: '💄', retailPrice: 8000, skidkzPrice: 6000, wholesalePrice: 4000, sellerId: 'seller1'),
    Product(id: '6', name: 'Бургер Сет', categoryIcon: '🍔', retailPrice: 5000, skidkzPrice: 4000, wholesalePrice: 3000, sellerId: 'seller2'),
    Product(id: '7', name: 'Зимние шины', categoryIcon: '🛞', retailPrice: 100000, skidkzPrice: 85000, wholesalePrice: 75000, sellerId: 'seller1'),
    Product(id: '8', name: 'Фитнес-трекер', categoryIcon: '⌚', retailPrice: 25000, skidkzPrice: 20000, wholesalePrice: 15000, sellerId: 'seller2'),
    Product(id: '9', name: 'Рюкзак городской', categoryIcon: '🎒', retailPrice: 18000, skidkzPrice: 14000, wholesalePrice: 10000, sellerId: 'seller1'),
    Product(id: '10', name: 'Набор инструментов', categoryIcon: '🔧', retailPrice: 45000, skidkzPrice: 38000, wholesalePrice: 30000, sellerId: 'seller2'),
  ];

  final List<Product> _pendingProducts = [];
  
  // Mock Orders
  final List<Order> _orders = [];

  // Mock Wallet
  double _wanghongBalance = 45000; // Starting balance for demo
  double _wanghongHold = 18000;

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get pendingProducts => List.unmodifiable(_pendingProducts);
  List<Order> get orders => List.unmodifiable(_orders);
  
  double get wanghongBalance => _wanghongBalance;
  double get wanghongHold => _wanghongHold;

  void addProduct(Product product) {
    _pendingProducts.add(product);
  }

  void approveProduct(String id) {
    final index = _pendingProducts.indexWhere((p) => p.id == id);
    if (index != -1) {
      final product = _pendingProducts.removeAt(index);
      _products.add(product);
    }
  }

  void rejectProduct(String id) {
    _pendingProducts.removeWhere((p) => p.id == id);
  }

  void createOrder(Product product, String promoCode) {
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: product.name,
      price: promoCode == 'IVAN25' ? product.skidkzPrice.toDouble() : product.retailPrice.toDouble(),
      status: 'Оплачен',
      date: DateTime.now(),
      promoCode: promoCode,
      sellerId: product.sellerId,
    );
    _orders.add(order);

    if (promoCode == 'IVAN25') {
      _wanghongHold += wanghongCommission;
    }
  }
  
  void requestWithdrawal() {
    if (_wanghongBalance >= minWithdrawal) {
      _wanghongBalance = 0; // Simple demo reset
    }
  }
}

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