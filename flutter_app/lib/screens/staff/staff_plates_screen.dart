import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class StaffPlatesScreen extends StatefulWidget {
  const StaffPlatesScreen({super.key});

  @override
  State<StaffPlatesScreen> createState() => _StaffPlatesScreenState();
}

class _StaffPlatesScreenState extends State<StaffPlatesScreen> {
  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  List<dynamic> _summary = [];
  int _totalPlates = 0;
  int _activeOrderCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getPlatesSummary(token);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        setState(() {
          _summary = (data['summary'] as List<dynamic>?) ?? [];
          _totalPlates = data['totalPlates'] as int? ?? 0;
          _activeOrderCount = data['activeOrderCount'] as int? ?? 0;
          _loading = false;
        });
      } else {
        setState(() { _error = res['message'] as String? ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kCard,
        title: const Text('Plates to Prepare', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetch),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: _kOrange,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            _SummaryTile(label: 'Total Plates', value: '$_totalPlates', icon: Icons.set_meal, color: _kOrange),
                            const SizedBox(width: 12),
                            _SummaryTile(label: 'Active Orders', value: '$_activeOrderCount', icon: Icons.receipt_long, color: Colors.blue),
                          ]),
                        ),
                      ),
                      if (_summary.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
                              SizedBox(height: 12),
                              Text('No active orders!', style: TextStyle(color: Colors.white54, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('All orders are delivered or cancelled.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            ]),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final item = _summary[i] as Map<String, dynamic>;
                                final plates = item['total_plates'] as int? ?? 0;
                                final name = item['name'] as String? ?? 'Unknown';
                                final category = item['category'] as String? ?? '';
                                final maxPlates = (_summary.isNotEmpty)
                                    ? ((_summary[0] as Map<String, dynamic>)['total_plates'] as int? ?? 1)
                                    : 1;
                                final fraction = plates / (maxPlates == 0 ? 1 : maxPlates);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _kCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                          if (category.isNotEmpty)
                                            Text(category, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                        ])),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(color: _kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kOrange.withOpacity(0.4))),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            const Icon(Icons.set_meal, color: _kOrange, size: 18),
                                            const SizedBox(width: 6),
                                            Text('$plates', style: const TextStyle(color: _kOrange, fontSize: 22, fontWeight: FontWeight.w900)),
                                            const SizedBox(width: 4),
                                            const Text('plates', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                          ]),
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: fraction,
                                          backgroundColor: Colors.white10,
                                          valueColor: AlwaysStoppedAnimation<Color>(_kOrange),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: _summary.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}
