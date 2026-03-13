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
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Summary header ──────────────────────────────────
                      Row(children: [
                        _StatBox(
                          label: 'Total Plates',
                          value: '$_totalPlates',
                          icon: Icons.set_meal,
                          color: _kOrange,
                        ),
                        const SizedBox(width: 12),
                        _StatBox(
                          label: 'Active Orders',
                          value: '$_activeOrderCount',
                          icon: Icons.receipt_long,
                          color: Colors.blue,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      if (_summary.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: const Column(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
                              SizedBox(height: 12),
                              Text('No active orders!', style: TextStyle(color: Colors.white54, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('Nothing to prepare right now.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                        )
                      else ...[
                        // ── Section title ──────────────────────────────────
                        Row(children: [
                          const Icon(Icons.restaurant, color: Color(0xFFFF6B35), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Preparation List  ·  ${_summary.length} item${_summary.length == 1 ? '' : 's'}',
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ]),
                        const SizedBox(height: 12),

                        // ── Numbered food preparation list ─────────────────
                        ...List.generate(_summary.length, (i) {
                          final item = _summary[i] as Map<String, dynamic>;
                          final plates = item['total_plates'] as int? ?? 0;
                          final name = item['name'] as String? ?? 'Unknown';
                          final category = item['category'] as String? ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                // Serial number
                                Container(
                                  width: 48,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: _kOrange.withOpacity(0.12),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      bottomLeft: Radius.circular(14),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: _kOrange.withOpacity(0.7),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                // Food name + category
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (category.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            category,
                                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                // Quantity badge — the most important number
                                Container(
                                  width: 80,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: _kOrange.withOpacity(0.15),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(14),
                                      bottomRight: Radius.circular(14),
                                    ),
                                    border: Border(left: BorderSide(color: _kOrange.withOpacity(0.25))),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$plates',
                                        style: const TextStyle(
                                          color: Color(0xFFFF6B35),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'plates',
                                        style: TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}
