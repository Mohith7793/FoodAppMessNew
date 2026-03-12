import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _loading = false;
  bool _placing = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get loading => _loading;
  bool get placing => _placing;
  String? get error => _error;

  Future<void> fetchOrders(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.getOrders(token);
      if (res['success'] == true) {
        final data = res['data'] as List<dynamic>;
        _orders = data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _error = 'Failed to load orders.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Order?> placeOrder({required String token, String? notes}) async {
    _placing = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.createOrder(token: token, notes: notes);
      if (res['success'] == true) {
        final order = Order.fromJson(res['data'] as Map<String, dynamic>);
        _orders.insert(0, order);
        notifyListeners();
        return order;
      }
      _error = res['message'] as String? ?? 'Failed to place order.';
      return null;
    } catch (e) {
      _error = 'Connection error.';
      return null;
    } finally {
      _placing = false;
      notifyListeners();
    }
  }
}
