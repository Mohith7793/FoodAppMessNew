import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/cart_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  int _qty = 1;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool get _isOutOfStock => !widget.product.isAvailable || widget.product.stock == 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_isOutOfStock) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    _controller.forward().then((_) => _controller.reverse());

    final cart = context.read<CartProvider>();
    final success = await cart.addToCart(
      token: token,
      productId: widget.product.id,
      quantity: _qty,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('${widget.product.name} added to cart!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
      setState(() => _qty = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isProcessing = cart.isProcessing(widget.product.id);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Opacity(
        opacity: _isOutOfStock ? 0.7 : 1.0,
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: widget.product.imageUrl != null
                          ? Image.network(
                              widget.product.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _FoodPlaceholder(),
                            )
                          : const _FoodPlaceholder(),
                    ),
                    // Category badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.product.category,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                    // Out of Stock overlay
                    if (_isOutOfStock)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Container(
                            color: Colors.black.withOpacity(0.45),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red[700],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info section
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                          color: _isOutOfStock ? Colors.grey[500] : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: _isOutOfStock ? Colors.grey : const Color(0xFFFF6B35),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      // Quantity selector + add button (disabled when out of stock)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _isOutOfStock
                                    ? Colors.grey[300]!
                                    : const Color(0xFFE0E0E0),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _MiniQtyBtn(
                                  icon: Icons.remove,
                                  onTap: (_qty > 1 && !_isOutOfStock)
                                      ? () => setState(() => _qty--)
                                      : null,
                                ),
                                Text(
                                  '$_qty',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _isOutOfStock ? Colors.grey : null,
                                  ),
                                ),
                                _MiniQtyBtn(
                                  icon: Icons.add,
                                  onTap: _isOutOfStock ? null : () => setState(() => _qty++),
                                ),
                              ],
                            ),
                          ),
                          // Add to cart button
                          GestureDetector(
                            onTap: (isProcessing || _isOutOfStock) ? null : _addToCart,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isOutOfStock
                                    ? Colors.grey[300]
                                    : isProcessing
                                        ? Colors.grey[300]
                                        : const Color(0xFFFF6B35),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _isOutOfStock
                                          ? Icons.remove_shopping_cart
                                          : Icons.add_shopping_cart,
                                      color: _isOutOfStock ? Colors.grey[500] : Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniQtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(
          icon,
          size: 14,
          color: onTap == null ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }
}

class _FoodPlaceholder extends StatelessWidget {
  const _FoodPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3E0),
      child: const Center(
        child: Icon(Icons.fastfood, color: Color(0xFFFF6B35), size: 48),
      ),
    );
  }
}
