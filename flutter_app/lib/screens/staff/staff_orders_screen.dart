import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  // Staff only see active orders by default
  static const _activeStatuses = ['pending', 'confirmed', 'preparing', 'ready'];
  static const _allStatuses = ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'];

  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  String? _filterStatus; // null = active only

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getGlobalOrders(token, status: _filterStatus, page: 1);
      if (res['success'] == true) {
        List<dynamic> orders = res['data'] as List<dynamic>? ?? [];
        // If no specific filter, show only active
        if (_filterStatus == null) {
          orders = orders.where((o) => _activeStatuses.contains(o['status'])).toList();
        }
        setState(() { _orders = orders; _loading = false; });
      } else {
        setState(() { _error = res['message'] as String? ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.updateOrderStatus(token, orderId, status);
      if (res['success'] == true && mounted) {
        setState(() {
          final idx = _orders.indexWhere((o) => o['id'] == orderId);
          if (idx != -1) _orders[idx] = {..._orders[idx] as Map<String, dynamic>, 'status': status};
        });
        // Remove from list if no longer active and showing active-only
        if (_filterStatus == null && !_activeStatuses.contains(status)) {
          setState(() => _orders.removeWhere((o) => o['id'] == orderId));
        }
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
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kCard,
        title: const Text('Orders Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetch),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _Chip('Active', _filterStatus == null, () { setState(() => _filterStatus = null); _fetch(); }),
                ..._allStatuses.map((s) => _Chip(
                  '${s[0].toUpperCase()}${s.substring(1)}',
                  _filterStatus == s,
                  () { setState(() => _filterStatus = s); _fetch(); },
                  color: _statusColor(s),
                )),
              ],
            ),
          ),
          // Count banner
          if (!_loading && _error == null)
            Container(
              color: _kCard,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Text('${_orders.length} order${_orders.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const Spacer(),
                if (_filterStatus == null)
                  const Text('Showing active only', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 12)),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kOrange))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white54)))
                    : _orders.isEmpty
                        ? Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 56),
                              const SizedBox(height: 12),
                              Text(_filterStatus == null ? 'No active orders' : 'No orders', style: const TextStyle(color: Colors.white54, fontSize: 15)),
                            ]),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: _kOrange,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (ctx, i) => _OrderCard(
                                order: _orders[i] as Map<String, dynamic>,
                                onStatusChange: _updateStatus,
                                statusColor: _statusColor,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _Chip(this.label, this.selected, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFFF6B35);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : Colors.white24),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white60, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(int, String) onStatusChange;
  final Color Function(String) statusColor;

  static const _statuses = ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'];

  const _OrderCard({required this.order, required this.onStatusChange, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final user = order['user'] as Map<String, dynamic>?;
    final items = (order['items'] as List<dynamic>?) ?? [];
    final date = order['created_at'] != null
        ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(order['created_at'] as String).toLocal())
        : '';
    final color = statusColor(status);
    final totalPlates = items.fold<int>(0, (s, i) => s + (i['quantity'] as int? ?? 0));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF16213E), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Center(child: Text('#${order['id']}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?['name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ])),
              // Plates count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  Text('$totalPlates', style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w900, fontSize: 18)),
                  const Text('plates', style: TextStyle(color: Colors.white54, fontSize: 10)),
                ]),
              ),
            ]),
          ),
          // Items
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: items.map((item) {
                  final p = item['product'] as Map<String, dynamic>?;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                    child: Text('${p?['name'] ?? 'Item'} ×${item['quantity']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  );
                }).toList(),
              ),
            ),
          // Status + quick action
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const Spacer(),
              // Quick deliver button for active orders
              if (!['delivered', 'cancelled'].contains(status))
                TextButton.icon(
                  onPressed: () => onStatusChange(order['id'] as int, 'delivered'),
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  label: const Text('Deliver', style: TextStyle(color: Colors.green, fontSize: 13)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                ),
              // Status dropdown
              PopupMenuButton<String>(
                color: const Color(0xFF1A1A2E),
                icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                tooltip: 'Change Status',
                onSelected: (s) => onStatusChange(order['id'] as int, s),
                itemBuilder: (_) => _statuses.map((s) => PopupMenuItem(
                  value: s,
                  child: Text('${s[0].toUpperCase()}${s.substring(1)}', style: TextStyle(color: statusColor(s))),
                )).toList(),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
