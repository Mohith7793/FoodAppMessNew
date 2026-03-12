import 'product_model.dart';

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final Product? product;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int,
      price: double.parse(json['price'].toString()),
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  double get subtotal => price * quantity;
}

class Order {
  final int id;
  final int userId;
  final double totalPrice;
  final String status;
  final String? notes;
  final List<OrderItem> items;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return Order(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      items: itemsJson.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'ready': return 'Ready for Pickup';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}
