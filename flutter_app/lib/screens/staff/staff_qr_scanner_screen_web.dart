/// Web-only QR scanner screen.
/// On web, mobile_scanner uses dart:io internally and crashes, so we provide
/// manual student-ID entry and an image-upload option instead.
import 'dart:convert';
import 'package:flutter/material.dart';
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

  bool _processing = false;
  final _manualCtrl = TextEditingController();

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
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
        final msg = res['message'] as String? ?? 'User not found';
        _showErrorDialog(title: 'Not Found', message: msg);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          title: 'Connection Error',
          message:
              'Could not reach the server.\n\nMake sure:\n• Backend is running\n• Browser can reach the server IP\n• IP in settings is correct\n\nDetails: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ]),
        content: Text(message,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: _kOrange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StudentOrdersSheet(
        user: user,
        orders: orders,
        token: context.read<AuthProvider>().token!,
      ),
    );
  }

  Future<void> _lookUpManual() async {
    final id = int.tryParse(_manualCtrl.text.trim());
    if (id == null) {
      _showErrorDialog(
          title: 'Invalid Input',
          message: 'Please enter a valid numeric student ID.');
      return;
    }
    _manualCtrl.clear();
    FocusScope.of(context).unfocus();
    await _fetchAndShowOrders(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      body: Column(
        children: [
          // ── Info area (replaces camera on web) ──────────────
          Expanded(
            flex: 3,
            child: Container(
              color: _kDark,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _kOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2,
                          color: _kOrange, size: 56),
                    ),
                    const SizedBox(height: 20),
                    const Text('Web QR Scanner',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Camera scanning is not available in the browser.\nUse the student ID lookup below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                    if (_processing) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: _kOrange),
                      const SizedBox(height: 8),
                      const Text('Looking up order...',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom actions: manual entry ────────────────────
          Container(
            color: _kCard,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              children: [
                const Text('Enter student ID manually',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) =>
                            _processing ? null : _lookUpManual(),
                        decoration: InputDecoration(
                          hintText: 'Student ID  (e.g. 5)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1A1A2E),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.tag,
                              color: Colors.white38, size: 18),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
}

// ── Bottom sheet: student order details ──────────────────────────────────────

class _StudentOrdersSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> orders;
  final String token;
  const _StudentOrdersSheet(
      {required this.user, required this.orders, required this.token});

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
    _orders = widget.orders
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
  }

  Future<void> _markDelivered(int orderId) async {
    try {
      final res =
          await ApiService.updateOrderStatus(widget.token, orderId, 'delivered');
      if (res['success'] == true && mounted) {
        setState(() {
          final idx = _orders.indexWhere((o) => o['id'] == orderId);
          if (idx != -1)
            _orders[idx] = {..._orders[idx], 'status': 'delivered'};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Marked as delivered'), backgroundColor: Colors.green),
        );
      }
    } catch (_) {}
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] as String? ?? 'Student';
    final email = widget.user['email'] as String? ?? '';

    final activeOrders = _orders
        .where((o) => !['delivered', 'cancelled'].contains(o['status']))
        .toList();
    final totalPlates = activeOrders.fold<int>(0, (sum, o) {
      final items = (o['items'] as List<dynamic>?) ?? [];
      return sum +
          items.fold<int>(0, (s, i) => s + (i['quantity'] as int? ?? 0));
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _kOrange.withOpacity(0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                        color: _kOrange,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17)),
                    Text(email,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                )),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kOrange.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text('$totalPlates',
                          style: const TextStyle(
                              color: _kOrange,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1)),
                      const Text('plates',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: _orders.isEmpty
                ? const Center(
                    child: Text('No orders found',
                        style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final order = _orders[i];
                      final status = order['status'] as String? ?? 'pending';
                      final items = (order['items'] as List<dynamic>?) ?? [];
                      final color = _statusColor(status);
                      final isActive =
                          !['delivered', 'cancelled'].contains(status);
                      final date = order['created_at'] != null
                          ? DateFormat('dd MMM, hh:mm a').format(
                              DateTime.parse(order['created_at'] as String)
                                  .toLocal())
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
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 8),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(status.toUpperCase(),
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                Text('Order #${order['id']}',
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 13)),
                                const Spacer(),
                                Text(date,
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                              ]),
                            ),
                            if (items.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 0, 14, 8),
                                child: Column(
                                  children: items.map((item) {
                                    final p =
                                        item['product'] as Map<String, dynamic>?;
                                    final qty = item['quantity'] as int? ?? 0;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Row(children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                              color:
                                                  _kOrange.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Center(
                                              child: Text('$qty',
                                                  style: const TextStyle(
                                                      color: _kOrange,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 13))),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(p?['name'] ?? 'Item',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                        Text(
                                            '× $qty plate${qty > 1 ? 's' : ''}',
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12)),
                                      ]),
                                    );
                                  }).toList(),
                                ),
                              ),
                            if (isActive)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _markDelivered(order['id'] as int),
                                    icon: const Icon(
                                        Icons.check_circle_outline,
                                        size: 18),
                                    label: const Text('Mark as Delivered'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
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
