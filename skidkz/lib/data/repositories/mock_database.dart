import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/data/models/order_model.dart';
import 'package:skidkz/data/models/product_model.dart';
import 'package:skidkz/data/models/user_model.dart';

// --- MOCK DATA ---

final _initialUsers = [
  User(id: 'u1', name: 'Buyer John', phoneNumber: '7771112233', role: UserRole.buyer),
  User(id: 'u2', name: 'Wanghong Ivan', phoneNumber: '7774445566', role: UserRole.wanghong, promoCode: 'IVAN25'),
  User(id: 'u3', name: 'Seller Shop', phoneNumber: '7777778899', role: UserRole.seller),
  User(id: 'u4', name: 'Admin Boss', phoneNumber: '7770000000', role: UserRole.admin),
];

final _initialProducts = [
  Product(
    id: 'p1',
    sellerId: 'u3',
    title: 'Winter Tires Set (4pcs)',
    description: 'Premium studded tires 205/55 R16. Reliable grip on ice.',
    retailPrice: 100000,
    wholesalePrice: 75000,
    skidkzPrice: 85000,
    type: ProductType.goods,
    status: ProductStatus.approved,
    imageUrl: 'https://via.placeholder.com/300?text=Tires',
  ),
  Product(
    id: 'p2',
    sellerId: 'u3',
    title: 'Smartphone X 128GB',
    description: 'Latest model with amazing camera and battery life.',
    retailPrice: 450000,
    wholesalePrice: 380000,
    skidkzPrice: 400000,
    type: ProductType.goods,
    status: ProductStatus.approved,
    imageUrl: 'https://via.placeholder.com/300?text=Phone',
  ),
  Product(
    id: 'p3',
    sellerId: 'u3',
    title: 'Premium Jacket',
    description: 'Waterproof, warm, and stylish for city winters.',
    retailPrice: 50000,
    wholesalePrice: 30000,
    skidkzPrice: 40000,
    type: ProductType.goods,
    status: ProductStatus.approved,
    imageUrl: 'https://via.placeholder.com/300?text=Jacket',
  ),
  Product(
    id: 'p4',
    sellerId: 'u3',
    title: 'Tire Fitting Service',
    description: 'Full change of 4 wheels + balancing.',
    retailPrice: 15000,
    wholesalePrice: 8000,
    skidkzPrice: 10000,
    type: ProductType.service,
    status: ProductStatus.approved,
    imageUrl: 'https://via.placeholder.com/300?text=Service',
  ),
  Product(
    id: 'p5',
    sellerId: 'u3',
    title: 'Beauty Salon Voucher',
    description: 'Manicure + Pedicure set.',
    retailPrice: 20000,
    wholesalePrice: 10000,
    skidkzPrice: 15000,
    type: ProductType.service,
    status: ProductStatus.pending,
    imageUrl: 'https://via.placeholder.com/300?text=Salon',
  ),
];

final _initialOrders = [
  Order(
    id: 'o1',
    buyerId: 'u1',
    sellerId: 'u3',
    product: _initialProducts[0],
    amount: 85000,
    promoCode: 'IVAN25',
    status: OrderStatus.paid,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    earningStatus: EarningStatus.hold,
  ),
  Order(
    id: 'o2',
    buyerId: 'u1',
    sellerId: 'u3',
    product: _initialProducts[3],
    amount: 10000,
    promoCode: 'IVAN25',
    status: OrderStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    earningStatus: EarningStatus.available, // > 14 days
  ),
];

// --- PROVIDERS ---

// Auth State
class AuthNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void login(UserRole role) {
    // Mock login by picking the first user of that role
    state = _initialUsers.firstWhere((u) => u.role == role);
  }

  void logout() {
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

// Products State
class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => _initialProducts;

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

final productsProvider = NotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

// Orders State
class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => _initialOrders;

  void addOrder(Order order) {
    state = [order, ...state];
  }

  void updateOrderStatus(String id, OrderStatus status) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: status) else o
    ];
  }

  void blockEarning(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(earningStatus: EarningStatus.blocked) else o
    ];
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);
