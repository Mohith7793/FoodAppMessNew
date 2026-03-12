import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getDashboard(token);
      if (res['success'] == true) {
        setState(() { _data = res['data'] as Map<String, dynamic>; _loading = false; });
      } else {
        setState(() { _error = res['message'] as String? ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetch),
          if (MediaQuery.of(context).size.width < 600)
            IconButton(icon: const Icon(Icons.logout, color: Colors.white70), onPressed: () => context.read<AuthProvider>().logout()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
                ]))
              : _buildContent(auth),
    );
  }

  Widget _buildContent(AuthProvider auth) {
    final d = _data!;
    final fmt = NumberFormat('#,##0.00');
    final staff = d['staff'] as Map<String, dynamic>? ?? {};
    final statusList = (d['ordersByStatus'] as List<dynamic>? ?? []);
    final recentOrders = (d['recentOrders'] as List<dynamic>? ?? []);

    return RefreshIndicator(
      onRefresh: _fetch,
      color: _kOrange,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${auth.user?.name ?? 'Admin'} 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),

            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 500 ? 3 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.4,
              children: [
                _StatCard('Total Orders', '${d['totalOrders'] ?? 0}', Icons.receipt_long, Colors.blue),
                _StatCard('Revenue', '₹${fmt.format(d['totalRevenue'] ?? 0)}', Icons.currency_rupee, Colors.green),
                _StatCard('Customers', '${d['totalCustomers'] ?? 0}', Icons.people, Colors.purple),
                _StatCard('Pending', '${d['pendingOrders'] ?? 0}', Icons.hourglass_empty, Colors.orange),
                _StatCard("Today's Orders", '${d['todayOrders'] ?? 0}', Icons.today, Colors.teal),
                _StatCard("Today's Revenue", '₹${fmt.format(d['todayRevenue'] ?? 0)}', Icons.trending_up, _kOrange),
              ],
            ),
            const SizedBox(height: 24),

            // Staff status
            _SectionTitle('Staff Status'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StaffChip('Active', staff['active'] ?? 0, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _StaffChip('Inactive', staff['inactive'] ?? 0, Colors.red)),
              ],
            ),
            const SizedBox(height: 24),

            // Orders by status
            _SectionTitle('Orders by Status'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: statusList.map((s) {
                final status = s['status'] as String;
                final count = s['count'] as int? ?? 0;
                return _StatusChip(status, count);
              }).toList(),
            ),

            if (recentOrders.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle('Recent Orders'),
              const SizedBox(height: 12),
              ...recentOrders.take(5).map((o) {
                final user = (o['user'] as Map<String, dynamic>?);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF16213E), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: _kOrange.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.receipt, color: _kOrange, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Order #${o['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(user?['name'] ?? 'Customer', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('₹${double.tryParse(o['total_price'].toString())?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(color: _kOrange, fontWeight: FontWeight.w800)),
                        _StatusBadge(o['status'] as String? ?? 'pending'),
                      ]),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800));
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF16213E), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const Spacer(),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _StaffChip extends StatelessWidget {
  final String label; final int count; final Color color;
  const _StaffChip(this.label, this.count, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status; final int count;
  const _StatusChip(this.status, this.count);
  static Color _color(String s) {
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
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.3))),
      child: Text('${status[0].toUpperCase()}${status.substring(1)}: $count', style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);
  static Color _color(String s) {
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
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
