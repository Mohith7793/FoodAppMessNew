import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../models/cart_model.dart';
import 'order_success_screen.dart';
import '../config/app_config.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (items.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              label: const Text('Clear', style: TextStyle(color: Colors.white70)),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: cart.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : items.isEmpty
              ? const _EmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => _CartItemTile(item: items[i]),
                      ),
                    ),
                    _OrderSummary(items: items, total: cart.total),
                  ],
                ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final token = context.read<AuthProvider>().token!;
              await context.read<CartProvider>().clearCart(token);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final token = context.read<AuthProvider>().token!;
    final isProcessing = cart.isProcessing(item.productId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.product.imageUrl != null
                  ? Image.network(
                      AppConfig.resolveImageUrl(item.product.imageUrl),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _FoodPlaceholder(size: 72),
                    )
                  : _FoodPlaceholder(size: 72),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.product.price.toStringAsFixed(0)} each',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFFF6B35)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyButton(
                              icon: Icons.remove,
                              onTap: isProcessing
                                  ? null
                                  : () async {
                                      if (item.quantity == 1) {
                                        await cart.removeItem(token: token, productId: item.productId);
                                      } else {
                                        await cart.updateQuantity(
                                          token: token,
                                          productId: item.productId,
                                          quantity: item.quantity - 1,
                                        );
                                      }
                                    },
                            ),
                            isProcessing
                                ? const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: Center(
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  )
                                : Container(
                                    constraints: const BoxConstraints(minWidth: 30),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                            _QtyButton(
                              icon: Icons.add,
                              onTap: isProcessing
                                  ? null
                                  : () => cart.updateQuantity(
                                        token: token,
                                        productId: item.productId,
                                        quantity: item.quantity + 1,
                                      ),
                            ),
                          ],
                        ),
                      ),
                      // Subtotal
                      Text(
                        '₹${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: onTap == null ? Colors.grey : const Color(0xFFFF6B35)),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final List<CartItem> items;
  final double total;

  const _OrderSummary({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    final itemCount = items.fold(0, (s, i) => s + i.quantity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$itemCount item${itemCount > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600])),
              Text('₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Place Order'),
              onPressed: () => _placeOrder(context),
            ),
          ),
        ],
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceOrderSheet(cartContext: context),
    );
  }
}

class _PlaceOrderSheet extends StatefulWidget {
  final BuildContext cartContext;
  const _PlaceOrderSheet({required this.cartContext});

  @override
  State<_PlaceOrderSheet> createState() => _PlaceOrderSheetState();
}

class _PlaceOrderSheetState extends State<_PlaceOrderSheet> {
  final _notesCtrl = TextEditingController();

  Future<void> _confirm() async {
    final token = context.read<AuthProvider>().token!;
    final orders = context.read<OrderProvider>();
    final cart = context.read<CartProvider>();

    final order = await orders.placeOrder(token: token, notes: _notesCtrl.text.trim());
    if (order != null && mounted) {
      cart.clearLocalCart();
      final nav = Navigator.of(widget.cartContext);
      Navigator.pop(context); // close sheet
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orders.error ?? 'Failed to place order'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confirm Order',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Your order will be prepared shortly.',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Special Instructions (Optional)',
                hintText: 'e.g. Less spicy, No onion...',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: orders.placing ? null : _confirm,
                child: orders.placing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Confirm & Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodPlaceholder extends StatelessWidget {
  final double size;
  const _FoodPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.fastfood, color: const Color(0xFFFF6B35).withOpacity(0.5), size: size * 0.45),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 88, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
              )),
          const SizedBox(height: 8),
          Text('Add some delicious food!',
              style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
