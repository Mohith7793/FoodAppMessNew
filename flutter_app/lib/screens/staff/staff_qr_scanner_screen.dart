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

class _StaffQrScannerScreenState extends State<StaffQrScannerScreen> {
  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  MobileScannerController? _cameraCtrl;
  bool _scanning = true;
  bool _processing = false;

  // Manual entry fallback
  final _manualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cameraCtrl = MobileScannerController();
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (!_scanning || _processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final userId = int.tryParse(raw.trim());
    if (userId == null) return;
    setState(() { _scanning = false; _processing = true; });
    await _fetchAndShowOrders(userId);
  }

  Future<void> _fetchAndShowOrders(int userId) async {
    setState(() => _processing = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getOrdersByUser(token, userId);
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        await _showOrdersSheet(data);
      } else {
        _showError(res['message'] as String? ?? 'User not found');
      }
    } catch (e) {
      if (mounted) _showError('Connection error');
    } finally {
      if (mounted) setState(() { _scanning = true; _processing = false; });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.red,
    ));
  }

  Future<void> _showOrdersSheet(Map<String, dynamic> data) async {
    final user = data['user'] as Map<String, dynamic>;
    final orders = (data['orders'] as List<dynamic>?) ?? [];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StudentOrdersSheet(user: user, orders: orders, token: context.read<AuthProvider>().token!),
    );
  }

  void _resetScan() => setState(() { _scanning = true; _processing = false; });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      body: Column(
        children: [
          // Camera scanner
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _cameraCtrl,
                  onDetect: _onBarcodeDetected,
                ),
                // Overlay frame
                Center(
                  child: Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: _kOrange, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
                  ),
                // Top label
                Positioned(
                  top: 16, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Point camera at student\'s QR code', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Manual entry section
          Container(
            color: _kCard,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [
                  const Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or enter manually', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
                        decoration: InputDecoration(
                          hintText: 'Enter Student ID',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true, fillColor: const Color(0xFF1A1A2E),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _processing ? null : () {
                        final id = int.tryParse(_manualCtrl.text.trim());
                        if (id == null) { _showError('Enter a valid numeric ID'); return; }
                        _manualCtrl.clear();
                        _fetchAndShowOrders(id);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _kOrange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Look Up'),
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
}

// ── Bottom sheet showing scanned student's orders ─────────────────────────────

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
  static const _kCard = Color(0xFF16213E);
  static const _kDark = Color(0xFF1A1A2E);

  late List<dynamic> _orders;

  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.orders);
  }

  Future<void> _markDelivered(int orderId) async {
    try {
      final res = await ApiService.updateOrderStatus(widget.token, orderId, 'delivered');
      if (res['success'] == true && mounted) {
        setState(() {
          final idx = _orders.indexWhere((o) => o['id'] == orderId);
          if (idx != -1) _orders[idx] = {..._orders[idx] as Map<String, dynamic>, 'status': 'delivered'};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as delivered'), backgroundColor: Colors.green),
        );
      }
    } catch (_) {}
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] as String? ?? 'Student';
    final email = widget.user['email'] as String? ?? '';
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          // Student header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: _kOrange.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(color: _kOrange, fontSize: 20, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ])),
                // Plates badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: _kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kOrange.withOpacity(0.4))),
                  child: Column(children: [
                    Text('$totalPlates', style: const TextStyle(color: _kOrange, fontSize: 22, fontWeight: FontWeight.w900)),
                    const Text('plates', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ]),
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
                      final order = _orders[i] as Map<String, dynamic>;
                      final status = order['status'] as String? ?? 'pending';
                      final items = (order['items'] as List<dynamic>?) ?? [];
                      final date = order['created_at'] != null
                          ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(order['created_at'] as String).toLocal())
                          : '';
                      final color = _statusColor(status);
                      final isActive = !['delivered', 'cancelled'].contains(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.25))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Text('Order #${order['id']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                const Spacer(),
                                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ]),
                            ),
                            // Items
                            if (items.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: items.map((item) {
                                    final p = item['product'] as Map<String, dynamic>?;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(children: [
                                        const Icon(Icons.circle, size: 5, color: Colors.white38),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(p?['name'] ?? 'Item', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                        Text('× ${item['quantity']}', style: const TextStyle(color: _kOrange, fontWeight: FontWeight.w700, fontSize: 13)),
                                      ]),
                                    );
                                  }).toList(),
                                ),
                              ),
                            // Mark delivered button
                            if (isActive)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
