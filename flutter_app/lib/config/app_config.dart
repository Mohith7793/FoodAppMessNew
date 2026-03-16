/// ─────────────────────────────────────────────────────────────────────────────
/// SERVER CONFIGURATION
/// ─────────────────────────────────────────────────────────────────────────────
///
/// [androidHost]  — your Mac's WiFi IP (used by Android physical device).
///   Find it:  ifconfig en0 | grep "inet " | awk '{print $2}'
///
/// [iosSimulatorHost] — always 'localhost' for the iOS Simulator, which runs
///   on the Mac itself and cannot reach the Mac via its own WiFi IP.
///
/// • Android device   → androidHost
/// • iOS Simulator    → localhost (iosSimulatorHost)
/// • Real iPhone/iPad → change iosSimulatorHost to the same WiFi IP as Android
/// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io' show Platform;

class AppConfig {
  /// Mac's current WiFi IP — used by Android devices on the same network.
  static const String androidHost = '10.36.141.213';

  /// iOS Simulator runs ON the Mac, so it reaches the backend via localhost.
  /// If testing on a real iPhone/iPad, change this to the same WiFi IP above.
  static const String iosSimulatorHost = 'localhost';

  static const int serverPort = 5001;

  /// Automatically picks the right host based on the running platform.
  static String get serverHost {
    if (Platform.isAndroid) return androidHost;
    return iosSimulatorHost; // iOS Simulator or real device
  }

  /// Full base URL for API calls
  static String get apiBaseUrl => 'http://$serverHost:$serverPort/api';

  /// Base URL for serving uploaded images
  static String get mediaBaseUrl => 'http://$serverHost:$serverPort';

  /// Resolve a potentially relative image path to a full URL.
  static String resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http')) return rawUrl;
    return '$mediaBaseUrl$rawUrl';
  }
}
