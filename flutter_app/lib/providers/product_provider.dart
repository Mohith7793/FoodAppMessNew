import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _loading = false;
  String? _error;
  String _selectedCategory = 'All';

  List<Product> get products => _selectedCategory == 'All'
      ? _products
      : _products.where((p) => p.category == _selectedCategory).toList();

  List<Product> get allProducts => _products;
  bool get loading => _loading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  Future<void> fetchProducts({String? search}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.getProducts(search: search);
      if (res['success'] == true) {
        final data = res['data'] as List<dynamic>;
        _products = data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _error = res['message'] as String? ?? 'Failed to load products.';
      }
    } catch (e) {
      _error = 'Connection error. Make sure backend is running.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
