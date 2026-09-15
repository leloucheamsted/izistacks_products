import 'package:flutter_test/flutter_test.dart';
import 'package:izistacks_products/models/product.dart';

Product product({double price = 9.99, String category = 'beauty'}) => Product(
  id: 1,
  title: 'Test',
  price: price,
  category: category,
  thumbnail: '',
);

void main() {
  test('priceLabel', () {
    expect(product(price: 9.99).priceLabel, '\$9.99');
    expect(product(price: 1899.99).priceLabel, '\$1,899.99');
    expect(product(price: 1234567).priceLabel, '\$1,234,567.00');
  });

  test('categoryLabel', () {
    expect(product(category: 'beauty').categoryLabel, 'Beauty');
    expect(
      product(category: 'home-decoration').categoryLabel,
      'Home decoration',
    );
    expect(product(category: '').categoryLabel, '');
  });

  test('fromJson sans category ni thumbnail', () {
    final p = Product.fromJson({'id': 3, 'title': 'X', 'price': 2});
    expect(p.price, 2.0);
    expect(p.category, '');
    expect(p.thumbnail, '');
  });
}
