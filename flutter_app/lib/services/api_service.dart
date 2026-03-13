import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ Mac + iOS Simulator / Chrome:
  static const String baseUrl = 'http://localhost:5001/api';
  // 🤖 Android Emulator — uncomment this instead:
  // static const String baseUrl = 'http://10.0.2.2:5001/api';
  // 📱 Physical device — use your Mac's WiFi IP:
  // static const String baseUrl = 'http://192.168.X.X:5001/api';

  static Map<String, String> _headers({String? token, bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // ── AUTH ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({required String name, required String email, required String password}) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/register'), headers: _headers(), body: jsonEncode({'name': name, 'email': email, 'password': password}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> registerAdmin({required String name, required String email, required String password, required String adminSecret}) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/register-admin'), headers: _headers(), body: jsonEncode({'name': name, 'email': email, 'password': password, 'admin_secret': adminSecret}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/login'), headers: _headers(), body: jsonEncode({'email': email, 'password': password}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── PRODUCTS (customer) ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProducts({String? category, String? search, int page = 1}) async {
    var uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
      if (category != null) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page.toString(),
      'limit': '20',
    });
    final res = await http.get(uri, headers: _headers());
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── CART ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCart(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/cart'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> addToCart({required String token, required int productId, required int quantity}) async {
    final res = await http.post(Uri.parse('$baseUrl/cart/add'), headers: _headers(token: token), body: jsonEncode({'product_id': productId, 'quantity': quantity}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateCartItem({required String token, required int productId, required int quantity}) async {
    final res = await http.put(Uri.parse('$baseUrl/cart/update'), headers: _headers(token: token), body: jsonEncode({'product_id': productId, 'quantity': quantity}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> removeFromCart({required String token, required int productId}) async {
    final res = await http.delete(Uri.parse('$baseUrl/cart/remove'), headers: _headers(token: token), body: jsonEncode({'product_id': productId}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> clearCart(String token) async {
    final res = await http.delete(Uri.parse('$baseUrl/cart/clear'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── ORDERS (customer) ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createOrder({required String token, String? notes}) async {
    final res = await http.post(Uri.parse('$baseUrl/orders/create'), headers: _headers(token: token), body: jsonEncode({'notes': notes}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getOrders(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/orders'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── ADMIN: DASHBOARD ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboard(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/dashboard'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── ADMIN: PRODUCTS ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminProducts(String token, {String? search}) async {
    final uri = Uri.parse('$baseUrl/admin/products').replace(queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final res = await http.get(uri, headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createProduct(String token, Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/products'), headers: _headers(token: token), body: jsonEncode(data));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProduct(String token, int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('$baseUrl/products/$id'), headers: _headers(token: token), body: jsonEncode(data));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> deleteProduct(String token, int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadProductImage(String token, int productId, Uint8List imageBytes, String fileName) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/admin/products/$productId/image'));
    req.headers['Authorization'] = 'Bearer $token';
    req.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: fileName));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── ADMIN: STAFF ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStaff(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/staff'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createStaff(String token, {required String name, required String email, required String password}) async {
    final res = await http.post(Uri.parse('$baseUrl/admin/staff'), headers: _headers(token: token), body: jsonEncode({'name': name, 'email': email, 'password': password}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> toggleStaff(String token, int staffId) async {
    final res = await http.put(Uri.parse('$baseUrl/admin/staff/$staffId/toggle'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> deleteStaff(String token, int staffId) async {
    final res = await http.delete(Uri.parse('$baseUrl/admin/staff/$staffId'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── ADMIN: GLOBAL ORDERS ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getGlobalOrders(String token, {String? status, int page = 1}) async {
    final uri = Uri.parse('$baseUrl/admin/orders').replace(queryParameters: {
      if (status != null) 'status': status,
      'page': page.toString(),
      'limit': '30',
    });
    final res = await http.get(uri, headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateOrderStatus(String token, int orderId, String status) async {
    final res = await http.put(Uri.parse('$baseUrl/admin/orders/$orderId/status'), headers: _headers(token: token), body: jsonEncode({'status': status}));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── STAFF: QR SCAN — orders for a specific student ─────────────────────────

  static Future<Map<String, dynamic>> getOrdersByUser(String token, int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/orders/user/$userId'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── STAFF: PLATES SUMMARY ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPlatesSummary(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/orders/plates'), headers: _headers(token: token));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
