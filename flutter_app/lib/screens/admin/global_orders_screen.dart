import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class GlobalOrdersScreen extends StatefulWidget {
  const GlobalOrdersScreen({super.key});
  @override
  State<GlobalOrdersScreen> createState() => _GlobalOrdersScreenState();
}

class _GlobalOrdersScreenState extends State<GlobalOrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  String? _filterStatus;

  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);
  static const _statuses = ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'];

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getGlobalOrders(token, status: _filterStatus);
      if (res['success'] == true) {
        setState(() { _orders = res['data'] as List<dynamic>? ?? []; _loading = false; });
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
      if (res['success'] == true) _fetch();
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
        title: const Text('All Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetch),
        ],
      ),
      body: Column(
        children: [
          // Status filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip('All', _filterStatus == null, () { setState(() => _filterStatus = null); _fetch(); }),
                ..._statuses.map((s) => _FilterChip(
                  '${s[0].toUpperCase()}${s.substring(1)}',
                  _filterStatus == s,
                  () { setState(() => _filterStatus = s); _fetch(); },
                  color: _statusColor(s),
                )),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kOrange))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white54)))
                    : _orders.isEmpty
                        ? const Center(child: Text('No orders found', style: TextStyle(color: Colors.white54)))
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: _kOrange,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (ctx, i) => _OrderTile(order: _orders[i], onStatusChange: _updateStatus, statusColor: _statusColor),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap; final Color? color;
  const _FilterChip(this.label, this.selected, this.onTap, {this.color});
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

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(int, String) onStatusChange;
  final Color Function(String) statusColor;
  const _OrderTile({required this.order, required this.onStatusChange, required this.statusColor});

  static const _statuses = ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final user = order['user'] as Map<String, dynamic>?;
    final items = order['items'] as List<dynamic>? ?? [];
    final date = order['created_at'] != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(order['created_at'] as String).toLocal()) : '';
    final color = statusColor(status);
    final total = double.tryParse(order['total_price'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF16213E), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Center(child: Text('#${order['id']}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?['name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(user?['email'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('${items.length} items', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ],
            ),
          ),
          // Items preview
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Text(
                items.take(3).map((i) {
                  final p = i['product'] as Map<String, dynamic>?;
                  return '${p?['name'] ?? 'Item'} x${i['quantity']}';
                }).join(' · '),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Status update bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  color: const Color(0xFF1A1A2E),
                  icon: const Icon(Icons.edit_note, color: Colors.white54, size: 20),
                  tooltip: 'Update Status',
                  onSelected: (s) => onStatusChange(order['id'] as int, s),
                  itemBuilder: (_) => _statuses.map((s) => PopupMenuItem(
                    value: s,
                    child: Text('${s[0].toUpperCase()}${s.substring(1)}', style: TextStyle(color: statusColor(s))),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
