import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/product_repository.dart';
import 'package:skidkz/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

// -----------------------------------------------------------------------------
// STATE MANAGEMENT
// -----------------------------------------------------------------------------

class HomeState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;

  HomeState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
  });

  HomeState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
  }) {
    return HomeState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final ProductRepository _repository;

  HomeNotifier(this._repository) : super(HomeState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final newProducts = await _repository.fetchProducts(limit: 10);
      state = state.copyWith(
        products: newProducts,
        isLoading: false,
        hasMore: newProducts.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    if (state.products.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final lastProduct = state.products.last;
      final lastDocSnapshot = await FirebaseFirestore.instance.collection('products').doc(lastProduct.id).get();

      final newProducts = await _repository.fetchProducts(
        lastDocument: lastDocSnapshot,
        limit: 10,
      );

      state = state.copyWith(
        products: [...state.products, ...newProducts],
        isLoading: false,
        hasMore: newProducts.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final homeProvider = StateNotifierProvider.autoDispose<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(productRepositoryProvider));
});

// -----------------------------------------------------------------------------
// UI COMPONENTS
// -----------------------------------------------------------------------------

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Main scroll controller for the page
  final ScrollController _pageScrollController = ScrollController();
  // Horizontal scroll controller for the recommended section
  final ScrollController _recommendedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _recommendedScrollController.addListener(_onRecommendedScroll);
  }

  void _onRecommendedScroll() {
    // Trigger load more when near the right end of the horizontal list
    if (_recommendedScrollController.position.pixels >= _recommendedScrollController.position.maxScrollExtent - 200) {
      ref.read(homeProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _recommendedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      drawer: const Drawer(),
      body: CustomScrollView(
        controller: _pageScrollController,
        slivers: [
          // 1. Top Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const Gap(4),
                const Text('Almaty', style: TextStyle(fontSize: 14)),
                const Spacer(),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 44,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {},
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),

          // 2. Promo Banners
          SliverToBoxAdapter(
            child: Container(
              height: 160,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: PageView(
                controller: PageController(viewportFraction: 0.9),
                padEnds: false,
                children: [
                  _buildBanner(Colors.blue.shade300, "Super Sale"),
                  _buildBanner(Colors.red.shade300, "Hot Deals"),
                  _buildBanner(Colors.green.shade300, "New Arrivals"),
                ],
              ),
            ),
          ),

          // 3. Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategory(Icons.phone_android, "Phones"),
                  _buildCategory(Icons.laptop, "Laptops"),
                  _buildCategory(Icons.checkroom, "Clothes"),
                  _buildCategory(Icons.home, "Home"),
                  _buildCategory(Icons.sports_soccer, "Sport"),
                ],
              ),
            ),
          ),

          // 4. Recently Viewed
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Recently Viewed",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (context, index) => _buildMockProductCard(index),
              ),
            ),
          ),

          // 5. Recommended (Horizontal Infinite Scroll)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                "Recommended for you",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 260, // Height for the product cards
              child: ListView.separated(
                controller: _recommendedScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: homeState.products.length + (homeState.hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (context, index) {
                  if (index < homeState.products.length) {
                    return SizedBox(
                      width: 160,
                      child: ProductCard(product: homeState.products[index]),
                    );
                  } else {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ));
                  }
                },
              ),
            ),
          ),
          
          const SliverGap(20),
        ],
      ),
    );
  }

  Widget _buildBanner(Color color, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCategory(IconData icon, String label) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const Gap(8),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildMockProductCard(int index) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Mock Item", maxLines: 1, overflow: TextOverflow.ellipsis),
                const Gap(4),
                Text("\$${(index + 1) * 100}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
           BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                      : const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.2),
                ),
                const Gap(4),
                // Rating
                const Row(
                  children: [
                     Icon(Icons.star, size: 12, color: Colors.amber),
                     Gap(2),
                     Text("4.5 (10)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const Gap(6),
                // Bonus
                if (product.bonusPrice != null && product.bonusPrice! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                    child: Text("+${product.bonusPrice} B", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                const Gap(6),
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${product.price} ₸", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}