import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) context.read<OrderProvider>().fetchOrders(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final token = context.read<AuthProvider>().token;
              if (token != null) orders.fetchOrders(token);
            },
          ),
        ],
      ),
      body: orders.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : orders.orders.isEmpty
              ? const _EmptyOrders()
              : RefreshIndicator(
                  onRefresh: () async {
                    final token = context.read<AuthProvider>().token;
                    if (token != null) await orders.fetchOrders(token);
                  },
                  color: const Color(0xFFFF6B35),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.orders.length,
                    itemBuilder: (ctx, i) => _OrderCard(order: orders.orders[i]),
                  ),
                ),
    );
  }
}

String _paymentStatusLabel(String orderStatus) {
  switch (orderStatus) {
    case 'delivered':
      return 'Paid';
    case 'cancelled':
      return 'Cancelled';
    case 'confirmed':
    case 'preparing':
    case 'ready':
      return 'Confirmed';
    default:
      return 'Pending';
  }
}

Color _paymentStatusColor(String orderStatus) {
  switch (orderStatus) {
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'confirmed':
    case 'preparing':
    case 'ready':
      return Colors.blue;
    default:
      return Colors.orange;
  }
}

String _buildQRData(Order order) {
  return jsonEncode({
    'user_id': order.userId,
    'order_id': order.id,
    'payment_status': _paymentStatusLabel(order.status).toLowerCase(),
    'order_status': order.status,
    'total': order.totalPrice.toStringAsFixed(2),
    'items': order.items
        .map((i) => {
              'name': i.product?.name ?? 'Item #${i.productId}',
              'qty': i.quantity,
              'price': i.price.toStringAsFixed(2),
            })
        .toList(),
    'ordered_at': order.createdAt.toIso8601String(),
  });
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (order.status) {
      case 'pending': return Icons.hourglass_empty;
      case 'confirmed': return Icons.check_circle_outline;
      case 'preparing': return Icons.outdoor_grill;
      case 'ready': return Icons.restaurant;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toLocal());
    final payLabel = _paymentStatusLabel(order.status);
    final payColor = _paymentStatusColor(order.status);

    return GestureDetector(
      onTap: () => _showOrderDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.id}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(dateStr,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Order status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(order.statusLabel,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Payment status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: payColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: payColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payment, color: payColor, size: 12),
                            const SizedBox(width: 4),
                            Text('Payment: $payLabel',
                                style: TextStyle(
                                    color: payColor, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Items preview
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ...order.items.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF6B35),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.product?.name ?? 'Product',
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text('x${item.quantity}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      )),
                  if (order.items.length > 3)
                    Text('+${order.items.length - 3} more items',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${order.items.fold(0, (s, i) => s + i.quantity)} items',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      Row(
                        children: [
                          // QR icon hint
                          Icon(Icons.qr_code, color: Colors.grey[400], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '₹${order.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final Order order;
  const _OrderDetailSheet({required this.order});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  bool _showQR = false;

  @override
  Widget build(BuildContext context) {
    final payLabel = _paymentStatusLabel(widget.order.status);
    final payColor = _paymentStatusColor(widget.order.status);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(widget.order.createdAt.toLocal());

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${widget.order.id}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(dateStr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                  Text('₹${widget.order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF6B35),
                      )),
                ],
              ),
            ),
            // Payment status + QR toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: payColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: payColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payment, color: payColor, size: 14),
                        const SizedBox(width: 5),
                        Text('Payment: $payLabel',
                            style: TextStyle(
                                color: payColor, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!['delivered', 'cancelled'].contains(widget.order.status))
                    TextButton.icon(
                      onPressed: () => setState(() => _showQR = !_showQR),
                      icon: Icon(_showQR ? Icons.list : Icons.qr_code,
                          size: 18, color: const Color(0xFFFF6B35)),
                      label: Text(
                        _showQR ? 'View Items' : 'Show QR',
                        style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: _showQR ? _buildQRView() : _buildItemsList(ctrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Order QR Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Show this at the counter to collect your order',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: QrImageView(
              data: _buildQRData(widget.order),
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Order ID: #${widget.order.id}',
              style: const TextStyle(
                  color: Color(0xFFFF6B35), fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ScrollController ctrl) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(20),
      children: [
        ...widget.order.items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(item.product?.name ?? 'Product',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text('x${item.quantity}',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 12),
                  Text('₹${item.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            )),
        if (widget.order.notes != null && widget.order.notes!.isNotEmpty) ...[
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.note_alt_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.order.notes!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 88, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No orders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
              )),
          const SizedBox(height: 8),
          Text('Start ordering your favourite meals!',
              style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}
