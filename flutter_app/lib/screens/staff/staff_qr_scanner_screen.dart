import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class StaffQrScannerScreen extends StatefulWidget {
  const StaffQrScannerScreen({super.key});

  @override
  State<StaffQrScannerScreen> createState() => _StaffQrScannerScreenState();
}

class _StaffQrScannerScreenState extends State<StaffQrScannerScreen>
    with WidgetsBindingObserver {
  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  late final MobileScannerController _cameraCtrl;
  bool _processing = false;
  final _manualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraCtrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraCtrl.stop();
    } else if (state == AppLifecycleState.resumed) {
      _cameraCtrl.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    // Try plain integer first (profile QR code)
    int? userId = int.tryParse(raw.trim());

    // If not a plain int, try JSON (order QR code contains user_id)
    if (userId == null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final dynamic uid = json['user_id'];
        if (uid != null) userId = int.tryParse(uid.toString());
      } catch (_) {}
    }

    if (userId == null) return;

    // Stop camera while processing to prevent duplicate scans
    await _cameraCtrl.stop();
    await _fetchAndShowOrders(userId);
    // Restart camera after sheet is dismissed
    if (mounted) await _cameraCtrl.start();
  }

  Future<void> _fetchAndShowOrders(int userId) async {
    if (!mounted) return;
    setState(() => _processing = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getOrdersByUser(token, userId);
      if (!mounted) return;
      if (res['success'] == true) {
        await _showOrdersSheet(res['data'] as Map<String, dynamic>);
      } else {
        _showError(res['message'] as String? ?? 'User not found');
      }
    } catch (e) {
      if (mounted) _showError('Connection error');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _showOrdersSheet(Map<String, dynamic> data) async {
    if (!mounted) return;
    final user = data['user'] as Map<String, dynamic>;
    final orders = (data['orders'] as List<dynamic>?) ?? [];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StudentOrdersSheet(
        user: user,
        orders: orders,
        token: context.read<AuthProvider>().token!,
      ),
    );
  }

  Future<void> _lookUpManual() async {
    final id = int.tryParse(_manualCtrl.text.trim());
    if (id == null) { _showError('Enter a valid numeric ID'); return; }
    _manualCtrl.clear();
    FocusScope.of(context).unfocus();
    await _cameraCtrl.stop();
    await _fetchAndShowOrders(id);
    if (mounted) await _cameraCtrl.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      body: Column(
        children: [
          // ── Camera scanner ─────────────────────────────────────
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _cameraCtrl,
                  onDetect: _onBarcodeDetected,
                  errorBuilder: (ctx, error, child) => Container(
                    color: _kDark,
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 56),
                        const SizedBox(height: 12),
                        const Text('Camera unavailable', style: TextStyle(color: Colors.white54, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(error.errorCode.name, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _cameraCtrl.start(),
                          style: ElevatedButton.styleFrom(backgroundColor: _kOrange),
                          child: const Text('Retry Camera'),
                        ),
                      ]),
                    ),
                  ),
                ),
                // Scan overlay frame
                Center(
                  child: Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kOrange, width: 3),
                    ),
                    child: Stack(children: [
                      // Corner accents
                      _corner(top: 0, left: 0, rotate: 0),
                      _corner(top: 0, right: 0, rotate: 1),
                      _corner(bottom: 0, left: 0, rotate: 3),
                      _corner(bottom: 0, right: 0, rotate: 2),
                    ]),
                  ),
                ),
                // Processing overlay
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(color: Color(0xFFFF6B35)),
                        SizedBox(height: 12),
                        Text('Looking up order...', style: TextStyle(color: Colors.white70)),
                      ]),
                    ),
                  ),
                // Top hint
                Positioned(
                  top: 16, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.qr_code_scanner, color: Colors.white70, size: 16),
                        SizedBox(width: 6),
                        Text('Point at student\'s QR code', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
                // Torch toggle
                Positioned(
                  top: 16, right: 16,
                  child: ValueListenableBuilder(
                    valueListenable: _cameraCtrl,
                    builder: (_, state, __) => IconButton(
                      icon: Icon(
                        state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                        color: state.torchState == TorchState.on ? _kOrange : Colors.white54,
                        size: 28,
                      ),
                      onPressed: () => _cameraCtrl.toggleTorch(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Manual entry ───────────────────────────────────────
          Container(
            color: _kCard,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              children: [
                Row(children: [
                  const Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or enter student ID manually', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                  const Expanded(child: Divider(color: Colors.white12)),
                ]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _processing ? null : _lookUpManual(),
                        decoration: InputDecoration(
                          hintText: 'Student ID  (e.g. 5)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1A1A2E),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.tag, color: Colors.white38, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _processing ? null : _lookUpManual,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Look Up'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Corner accent widget for the scan frame
  Widget _corner({double? top, double? bottom, double? left, double? right, required int rotate}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: RotatedBox(
        quarterTurns: rotate,
        child: Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 3),
              left: BorderSide(color: Colors.white, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet: student order details ──────────────────────────────────────

class _StudentOrdersSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> orders;
  final String token;
  const _StudentOrdersSheet({required this.user, required this.orders, required this.token});

  @override
  State<_StudentOrdersSheet> createState() => _StudentOrdersSheetState();
}

class _StudentOrdersSheetState extends State<_StudentOrdersSheet> {
  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);

  late List<Map<String, dynamic>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = widget.orders.map((o) => Map<String, dynamic>.from(o as Map)).toList();
  }

  Future<void> _markDelivered(int orderId) async {
    try {
      final res = await ApiService.updateOrderStatus(widget.token, orderId, 'delivered');
      if (res['success'] == true && mounted) {
        setState(() {
          final idx = _orders.indexWhere((o) => o['id'] == orderId);
          if (idx != -1) _orders[idx] = {..._orders[idx], 'status': 'delivered'};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as delivered ✓'), backgroundColor: Colors.green),
        );
      }
    } catch (_) {}
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'pending':   return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready':     return Colors.teal;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] as String? ?? 'Student';
    final email = widget.user['email'] as String? ?? '';

    // Total plates across active (non-delivered/cancelled) orders
    final activeOrders = _orders.where((o) => !['delivered', 'cancelled'].contains(o['status'])).toList();
    final totalPlates = activeOrders.fold<int>(0, (sum, o) {
      final items = (o['items'] as List<dynamic>?) ?? [];
      return sum + items.fold<int>(0, (s, i) => s + (i['quantity'] as int? ?? 0));
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // Student header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _kOrange.withOpacity(0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(color: _kOrange, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    Text(email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                )),
                // Total plates badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kOrange.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text('$totalPlates', style: const TextStyle(color: _kOrange, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
                      const Text('plates', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          // Orders list
          Expanded(
            child: _orders.isEmpty
                ? const Center(child: Text('No orders found', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final order = _orders[i];
                      final status = order['status'] as String? ?? 'pending';
                      final items = (order['items'] as List<dynamic>?) ?? [];
                      final color = _statusColor(status);
                      final isActive = !['delivered', 'cancelled'].contains(status);
                      final date = order['created_at'] != null
                          ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(order['created_at'] as String).toLocal())
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _kDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                Text('Order #${order['id']}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                                const Spacer(),
                                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ]),
                            ),
                            // Items with quantities
                            if (items.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                                child: Column(
                                  children: items.map((item) {
                                    final p = item['product'] as Map<String, dynamic>?;
                                    final qty = item['quantity'] as int? ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(children: [
                                        Container(
                                          width: 30, height: 30,
                                          decoration: BoxDecoration(color: _kOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                          child: Center(child: Text('$qty', style: const TextStyle(color: _kOrange, fontWeight: FontWeight.w900, fontSize: 13))),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(p?['name'] ?? 'Item', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                        ),
                                        Text('× $qty plate${qty > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                      ]),
                                    );
                                  }).toList(),
                                ),
                              ),
                            // Mark delivered button
                            if (isActive)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _markDelivered(order['id'] as int),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Mark as Delivered'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
