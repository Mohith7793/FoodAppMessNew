import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _mealTimes = [
    {'label': 'Breakfast', 'icon': '🌅'},
    {'label': 'Lunch', 'icon': '☀️'},
    {'label': 'Dinner', 'icon': '🌙'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      final token = context.read<AuthProvider>().token;
      if (token != null) context.read<CartProvider>().fetchCart(token);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mess Food'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await products.fetchProducts();
          if (auth.token != null) await cart.fetchCart(auth.token!);
        },
        color: const Color(0xFFFF6B35),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(auth)),
            SliverToBoxAdapter(child: _buildSearchBar(products)),
            SliverToBoxAdapter(child: _buildMealTimeFilter(products)),
            SliverToBoxAdapter(child: _buildCategoryFilter(products)),
            if (products.loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
              )
            else if (products.error != null)
              SliverFillRemaining(child: _buildError(products))
            else if (products.products.isEmpty)
              const SliverFillRemaining(child: _EmptyProducts())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => ProductCard(product: products.products[i]),
                    childCount: products.products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${auth.user?.name.split(' ').first ?? 'Student'} 👋',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            "What's on your plate today?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ProductProvider products) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextFormField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search food items...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B35)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    products.fetchProducts();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
          if (value.length >= 2 || value.isEmpty) {
            products.fetchProducts(search: value.isEmpty ? null : value);
          }
        },
      ),
    );
  }

  Widget _buildMealTimeFilter(ProductProvider products) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meal Time',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _mealTimes.map((m) {
              final label = m['label']!;
              final icon = m['icon']!;
              final selected = products.selectedMealTime == label;
              return Expanded(
                child: GestureDetector(
                  onTap: () => products.setMealTime(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFF6B35) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? const Color(0xFFFF6B35) : const Color(0xFFE0E0E0),
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 8)]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.grey[700],
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ProductProvider products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Category',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final cat = products.categories[i];
              final selected = products.selectedCategory == cat && products.selectedMealTime == null;
              return GestureDetector(
                onTap: () => products.setCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFF6B35) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFFFF6B35) : const Color(0xFFE0E0E0),
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 8)]
                        : [],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey[700],
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildError(ProductProvider products) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(products.error ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => products.fetchProducts(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No items available',
              style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Check back later!', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}
