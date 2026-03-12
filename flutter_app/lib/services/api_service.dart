import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your backend IP when running on physical device
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS simulator

  static Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // AUTH
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // PRODUCTS
  static Future<Map<String, dynamic>> getProducts({
    String? category,
    String? search,
    int page = 1,
  }) async {
    var uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
      if (category != null) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page.toString(),
      'limit': '20',
    });
    final res = await http.get(uri, headers: _headers());
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // CART
  static Future<Map<String, dynamic>> getCart(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: _headers(token: token),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> addToCart({
    required String token,
    required int productId,
    required int quantity,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cart/add'),
      headers: _headers(token: token),
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required String token,
    required int productId,
    required int quantity,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/cart/update'),
      headers: _headers(token: token),
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> removeFromCart({
    required String token,
    required int productId,
  }) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/cart/remove'),
      headers: _headers(token: token),
      body: jsonEncode({'product_id': productId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> clearCart(String token) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/cart/clear'),
      headers: _headers(token: token),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ORDERS
  static Future<Map<String, dynamic>> createOrder({
    required String token,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/create'),
      headers: _headers(token: token),
      body: jsonEncode({'notes': notes}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOrders(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: _headers(token: token),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
