import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  static const _kOrange = Color(0xFFFF6B35);
  static const _kDark = Color(0xFF1A1A2E);
  static const _kCard = Color(0xFF16213E);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  String _generatedAt = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await ApiService.getForecast(token);
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        setState(() {
          _products = (data['products'] as List<dynamic>)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
          _generatedAt = data['generated_at'] as String? ?? '';
          _loading = false;
        });
      } else {
        setState(() { _error = res['message'] as String? ?? 'Failed to load forecast'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Connection error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kCard,
        title: const Row(
          children: [
            Icon(Icons.auto_graph, color: Color(0xFFFF6B35), size: 22),
            SizedBox(width: 8),
            Text('Demand Forecast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFFF6B35)),
                SizedBox(height: 14),
                Text('Running AI prediction model...', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ))
          : _error != null
              ? _buildError()
              : _products.isEmpty
                  ? _buildEmpty()
                  : _buildContent(),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white38, size: 56),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: _kOrange),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bar_chart, color: Colors.white24, size: 72),
        const SizedBox(height: 16),
        const Text('No delivered orders yet', style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Predictions will appear once orders are delivered.', style: TextStyle(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildContent() {
    return Column(
      children: [
        // Model info banner
        Container(
          width: double.infinity,
          color: _kCard,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kOrange.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology, color: Color(0xFFFF6B35), size: 14),
                        SizedBox(width: 5),
                        Text("Holt's Exponential Smoothing",
                            style: TextStyle(color: Color(0xFFFF6B35), fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('3-week forecast',
                        style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Trained on 8 weeks of delivered orders. Updated each refresh.',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),

        // Product cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            itemBuilder: (_, i) => _ProductForecastCard(product: _products[i]),
          ),
        ),
      ],
    );
  }
}

// ── Per-product forecast card ─────────────────────────────────────────────────

class _ProductForecastCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductForecastCard({required this.product});

  static const _kOrange = Color(0xFFFF6B35);
  static const _kCard = Color(0xFF16213E);
  static const _kDark = Color(0xFF1A1A2E);

  Color get _trendColor {
    switch (product['trend'] as String? ?? 'stable') {
      case 'up': return Colors.green;
      case 'down': return Colors.redAccent;
      default: return Colors.blue;
    }
  }

  IconData get _trendIcon {
    switch (product['trend'] as String? ?? 'stable') {
      case 'up': return Icons.trending_up;
      case 'down': return Icons.trending_down;
      default: return Icons.trending_flat;
    }
  }

  String get _trendLabel {
    switch (product['trend'] as String? ?? 'stable') {
      case 'up': return 'Rising demand';
      case 'down': return 'Falling demand';
      default: return 'Stable demand';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? 'Product';
    final category = product['category'] as String? ?? '';
    final nextWeek = product['next_week_plates'] as int? ?? 0;
    final totalDelivered = product['total_delivered'] as int? ?? 0;
    final history = (product['history'] as List<dynamic>?) ?? [];
    final forecast = (product['forecast'] as List<dynamic>?) ?? [];

    // Find max for bar scaling
    final allValues = [
      ...history.map((h) => (h['quantity'] as int? ?? 0)),
      ...forecast.map((f) => (f['quantity'] as int? ?? 0)),
    ];
    final maxVal = allValues.isEmpty ? 1 : allValues.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant, color: _kOrange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      if (category.isNotEmpty)
                        Text(category,
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                // Trend badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _trendColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _trendColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_trendIcon, color: _trendColor, size: 14),
                      const SizedBox(width: 4),
                      Text(_trendLabel, style: TextStyle(color: _trendColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Next week prediction — big number
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kOrange.withOpacity(0.2), _kOrange.withOpacity(0.05)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kOrange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFFF6B35), size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next Week Prediction', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      Text('Plates required', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
                Text(
                  '$nextWeek',
                  style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 34, fontWeight: FontWeight.w900, height: 1),
                ),
                const SizedBox(width: 6),
                const Text('plates', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Bar chart: history + forecast
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LegendDot(color: Colors.blue.shade300, label: 'Actual (last 4 wks)'),
                    const SizedBox(width: 16),
                    _LegendDot(color: _kOrange, label: 'Forecast'),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // History bars
                      ...history.map((h) {
                        final qty = h['quantity'] as int? ?? 0;
                        final label = _shortWeek(h['week'] as String? ?? '');
                        return _Bar(
                          value: qty,
                          max: maxVal,
                          color: Colors.blue.shade300,
                          label: label,
                          isActual: true,
                        );
                      }),
                      // Divider
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                        child: Container(width: 1, height: 50, color: Colors.white12),
                      ),
                      // Forecast bars
                      ...forecast.map((f) {
                        final qty = f['quantity'] as int? ?? 0;
                        final label = _shortWeek(f['week'] as String? ?? '');
                        return _Bar(
                          value: qty,
                          max: maxVal,
                          color: _kOrange,
                          label: label,
                          isActual: false,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer: total delivered
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Text(
              'Total delivered in last 8 weeks: $totalDelivered plates',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// "2025-W12" → "W12"
  String _shortWeek(String wk) {
    final parts = wk.split('-');
    return parts.length >= 2 ? parts[1] : wk;
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final int max;
  final Color color;
  final String label;
  final bool isActual;

  const _Bar({required this.value, required this.max, required this.color, required this.label, required this.isActual});

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final barH = (ratio * 52).clamp(4.0, 52.0);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (value > 0)
              Text('$value', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Container(
              height: barH,
              decoration: BoxDecoration(
                color: isActual ? color.withOpacity(0.7) : color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                border: !isActual ? Border.all(color: color, width: 1) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ],
  );
}
