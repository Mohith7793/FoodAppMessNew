/// ─────────────────────────────────────────────────────────────────────────────
/// SERVER CONFIGURATION
/// ─────────────────────────────────────────────────────────────────────────────
///
/// The server host is configurable at runtime via a settings dialog on the
/// login screen (tap the ⚙ icon). The value is saved in SharedPreferences so
/// it persists across app restarts.
///
/// Default fallbacks (used when no custom host has been saved):
///   • Android device   → androidDefaultHost  (your Mac's WiFi IP)
///   • iOS Simulator    → localhost
///
/// How to find your Mac's WiFi IP:
///   • Mac Terminal: ifconfig en0 | grep "inet " | awk '{print $2}'
///   • Windows cmd:  ipconfig | findstr "IPv4"
/// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _prefKey = 'server_host';
  static const String _prefPortKey = 'server_port';

  /// Fallback WiFi IP for Android when no custom host has been saved yet.
  static const String androidDefaultHost = '10.253.56.213';
  static const int defaultPort = 5001;

  // Runtime-mutable values (loaded from SharedPreferences at startup)
  static String? _customHost;
  static int? _customPort;

  /// Call once in main() before runApp().
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _customHost = prefs.getString(_prefKey);
    _customPort = prefs.getInt(_prefPortKey);
  }

  /// Persist a new host/port chosen by the user.
  static Future<void> save({required String host, required int port}) async {
    _customHost = host.trim();
    _customPort = port;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _customHost!);
    await prefs.setInt(_prefPortKey, _customPort!);
  }

  /// Clear saved config (reverts to platform defaults).
  static Future<void> reset() async {
    _customHost = null;
    _customPort = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    await prefs.remove(_prefPortKey);
  }

  static String get serverHost {
    if (_customHost != null && _customHost!.isNotEmpty) return _customHost!;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return androidDefaultHost;
    }
    return 'localhost'; // iOS Simulator, macOS, or web
  }

  static int get serverPort => _customPort ?? defaultPort;

  static String get apiBaseUrl => 'http://$serverHost:$serverPort/api';
  static String get mediaBaseUrl => 'http://$serverHost:$serverPort';

  static String resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http')) return rawUrl;
    return '$mediaBaseUrl$rawUrl';
  }
}
