import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  CartModel? _cart;
  bool _loading = false;
  String? _error;
  final Set<int> _processingItems = {};

  CartModel? get cart => _cart;
  bool get loading => _loading;
  String? get error => _error;
  List<CartItem> get items => _cart?.items ?? [];
  double get total => _cart?.total ?? 0;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool isProcessing(int productId) => _processingItems.contains(productId);

  Future<void> fetchCart(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.getCart(token);
      if (res['success'] == true) {
        _cart = CartModel.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      _error = 'Failed to load cart.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart({
    required String token,
    required int productId,
    required int quantity,
  }) async {
    _processingItems.add(productId);
    notifyListeners();
    try {
      final res = await ApiService.addToCart(token: token, productId: productId, quantity: quantity);
      if (res['success'] == true) {
        await fetchCart(token);
        return true;
      }
      _error = res['message'] as String?;
      return false;
    } catch (e) {
      _error = 'Failed to add item.';
      return false;
    } finally {
      _processingItems.remove(productId);
      notifyListeners();
    }
  }

  Future<void> updateQuantity({
    required String token,
    required int productId,
    required int quantity,
  }) async {
    _processingItems.add(productId);
    notifyListeners();
    try {
      // Optimistic update
      if (_cart != null) {
        if (quantity <= 0) {
          _cart!.items.removeWhere((i) => i.productId == productId);
        } else {
          final item = _cart!.items.firstWhere((i) => i.productId == productId);
          item.quantity = quantity;
        }
        _recalcTotal();
        notifyListeners();
      }
      await ApiService.updateCartItem(token: token, productId: productId, quantity: quantity);
      await fetchCart(token);
    } catch (e) {
      await fetchCart(token); // revert on error
    } finally {
      _processingItems.remove(productId);
      notifyListeners();
    }
  }

  Future<void> removeItem({required String token, required int productId}) async {
    _processingItems.add(productId);
    // Optimistic
    _cart?.items.removeWhere((i) => i.productId == productId);
    _recalcTotal();
    notifyListeners();
    try {
      await ApiService.removeFromCart(token: token, productId: productId);
      await fetchCart(token);
    } catch (e) {
      await fetchCart(token);
    } finally {
      _processingItems.remove(productId);
      notifyListeners();
    }
  }

  void _recalcTotal() {
    if (_cart == null) return;
    final newTotal = _cart!.items.fold(0.0, (s, i) => s + i.subtotal);
    _cart = CartModel(
      id: _cart!.id,
      userId: _cart!.userId,
      items: _cart!.items,
      total: newTotal,
    );
  }

  void clearLocalCart() {
    _cart = null;
    notifyListeners();
  }
}
