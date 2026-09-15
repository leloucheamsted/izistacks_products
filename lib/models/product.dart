class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final double price;
  final String category; // ex: "home-decoration"
  final String thumbnail;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  String get categoryLabel {
    if (category.isEmpty) return '';
    final s = category.replaceAll('-', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  String get priceLabel {
    final parts = price.toStringAsFixed(2).split('.');
    final n = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '\$$n.${parts[1]}';
  }
}
