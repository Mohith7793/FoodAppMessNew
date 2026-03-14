import 'product_model.dart';

class CartItem {
  final int id;
  final int cartId;
  final int productId;
  int quantity;
  final Product product;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      cartId: json['cart_id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int,
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : Product(id: json['product_id'] as int, name: 'Unknown', description: '', price: 0, stock: 0, category: 'Other', isAvailable: false),
    );
  }

  double get subtotal => product.price * quantity;
}

class CartModel {
  final int id;
  final int userId;
  final List<CartItem> items;
  final double total;

  const CartModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final cartData = json['cart'] as Map<String, dynamic>;
    final itemsJson = cartData['items'] as List<dynamic>? ?? [];
    return CartModel(
      id: cartData['id'] as int,
      userId: cartData['user_id'] as int,
      items: itemsJson.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
      total: double.parse(json['total']?.toString() ?? '0'),
    );
  }
}
