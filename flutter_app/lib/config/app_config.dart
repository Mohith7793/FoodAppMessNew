/// ─────────────────────────────────────────────────────────────────────────────
/// SERVER CONFIGURATION
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Change ONLY the [serverHost] line below to your Mac's current WiFi IP.
///
/// How to find your Mac's WiFi IP:
///   • Terminal: ifconfig en0 | grep "inet " | awk '{print $2}'
///   • System Settings → Wi-Fi → Details → IP Address
///
/// The IP must be reachable from both macOS and Android on the same WiFi.
/// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  /// Your Mac's current WiFi IP address (update when network changes)
  static const String serverHost = '10.36.141.213';

  static const int serverPort = 5001;

  /// Full base URL for API calls  (e.g. http://192.168.1.100:5001/api)
  static const String apiBaseUrl = 'http://$serverHost:$serverPort/api';

  /// Base URL for serving uploaded images (e.g. http://192.168.1.100:5001)
  static const String mediaBaseUrl = 'http://$serverHost:$serverPort';

  /// Resolve a potentially relative image path to a full URL.
  /// e.g. '/uploads/foo.jpg'  →  'http://192.168.1.100:5001/uploads/foo.jpg'
  ///      'http://...'        →  returned as-is
  static String resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http')) return rawUrl;
    return '$mediaBaseUrl$rawUrl';
  }
}
