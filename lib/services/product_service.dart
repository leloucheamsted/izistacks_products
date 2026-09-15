import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductException implements Exception {
  const ProductException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _url =
      'https://dummyjson.com/products?limit=30&select=id,title,price,category,thumbnail';

  Future<List<Product>> fetchProducts() async {
    http.Response response;
    try {
      response = await _client
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ProductException('Le serveur met trop de temps à répondre.');
    } on http.ClientException {
      // pas de réseau, DNS, etc. (http wrappe les SocketException)
      throw const ProductException(
        'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }

    if (response.statusCode != 200) {
      throw ProductException('Erreur serveur (${response.statusCode}).');
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['products'] as List;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ProductException('Réponse du serveur invalide.');
    }
  }
}
