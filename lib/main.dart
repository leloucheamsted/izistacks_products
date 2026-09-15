import 'package:flutter/material.dart';

import 'pages/products_page.dart';
import 'theme/izi_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Produits',
      debugShowCheckedModeBanner: false,
      theme: iziTheme(),
      home: const ProductsPage(),
    );
  }
}
