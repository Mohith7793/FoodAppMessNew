class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final int stock;
  final String category;
  final bool isAvailable;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.stock,
    required this.category,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'] as String?,
      stock: json['stock'] as int? ?? 0,
      category: json['category'] as String? ?? 'Other',
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}
