import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  UserModel? _user;
  bool _loading = false;
  String? _error;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isStaff => _user?.role == 'staff';
  bool get isAdminOrStaff => isAdmin || isStaff;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    final role = prefs.getString('user_role');
    final id = prefs.getInt('user_id');
    if (_token != null && id != null) {
      _user = UserModel(id: id, name: name ?? '', email: email ?? '', role: role ?? 'customer');
    }
    notifyListeners();
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.register(name: name, email: email, password: password);
      if (res['success'] == true) { await _saveSession(res); return true; }
      _error = res['message'] as String? ?? 'Registration failed.';
      return false;
    } catch (e) {
      _error = 'Cannot reach server at ${AppConfig.serverHost}:${AppConfig.serverPort}. '
            'Tap the server bar on the login screen to update the IP.'; return false;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<bool> registerAdmin({required String name, required String email, required String password, required String adminSecret}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.registerAdmin(name: name, email: email, password: password, adminSecret: adminSecret);
      if (res['success'] == true) { await _saveSession(res); return true; }
      _error = res['message'] as String? ?? 'Registration failed.';
      return false;
    } catch (e) {
      _error = 'Cannot reach server at ${AppConfig.serverHost}:${AppConfig.serverPort}. '
            'Tap the server bar on the login screen to update the IP.'; return false;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.login(email: email, password: password);
      if (res['success'] == true) { await _saveSession(res); return true; }
      _error = res['message'] as String? ?? 'Login failed.';
      return false;
    } catch (e) {
      _error = 'Cannot reach server at ${AppConfig.serverHost}:${AppConfig.serverPort}. '
            'Tap the server bar on the login screen to update the IP.'; return false;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<void> _saveSession(Map<String, dynamic> res) async {
    _token = res['token'] as String;
    final userData = res['user'] as Map<String, dynamic>;
    _user = UserModel.fromJson(userData);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setInt('user_id', _user!.id);
    await prefs.setString('user_name', _user!.name);
    await prefs.setString('user_email', _user!.email);
    await prefs.setString('user_role', _user!.role);
  }

  Future<void> logout() async {
    _token = null; _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
