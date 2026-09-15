# Test technique Flutter - liste de produits

Bonjour,

Voici ma réponse pour l'exercice : une liste de produits récupérée via une API, avec les états loading / erreur et un pull-to-refresh. Je l'ai fait en Flutter.

En résumé :

- l'API est dummyjson.com (30 produits), appel avec le package http et un timeout de 10s
- un StatefulWidget gère les 3 états, pas de state management vu qu'il n'y a qu'un écran
- au premier chargement et sur "Réessayer" on passe par un loader plein écran, et par un écran d'erreur si ça échoue
- le pull-to-refresh recharge sans le loader, et si ça échoue on garde la liste et on affiche un snackbar
- les erreurs réseau, timeout, code HTTP et json invalide ont chacune leur message
- le client http est injectable pour tester sans réseau : 7 tests widget et 3 tests unitaires, tout passe, flutter analyze ne remonte rien
- pour l'habillage j'ai repris les couleurs et les polices (Sora / Figtree) du site izistacks.com, et ajouté un filtre par type de produit

Pour lancer : `flutter pub get` puis `flutter run`. Les tests avec `flutter test`.

Le code complet est ci-dessous, fichier par fichier. Les deux polices sont dans `assets/fonts/` (téléchargées depuis Google Fonts).

## pubspec.yaml

```yaml
name: izistacks_products
description: "A new Flutter project."
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.13.3

dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  fonts:
    - family: Sora
      fonts:
        - asset: assets/fonts/Sora-Variable.ttf
    - family: Figtree
      fonts:
        - asset: assets/fonts/Figtree-Variable.ttf
```

## lib/main.dart

```dart
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
```

## lib/theme/izi_theme.dart

```dart
import 'package:flutter/material.dart';

// Couleurs et polices reprises du site izistacks.com

class IziColors {
  static const ink = Color(0xFF0B1220);
  static const secondary = Color(0xFF51607A);
  static const muted = Color(0xFF93A1B7);
  static const border = Color(0xFFE3E9F2);
  static const surface = Color(0xFFFBFDFF);
  static const surfaceAlt = Color(0xFFF5F8FC);
  static const blue = Color(0xFF2563EB);
  static const navy = Color(0xFF1E3A8A);
  static const cyan = Color(0xFF22D3EE);
  static const blueTint = Color(0xFFEFF4FF);
  static const danger = Color(0xFFDC2626);

  // le dégradé du logo
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, blue, cyan],
  );
}

class IziFonts {
  static const display = 'Sora';
  static const body = 'Figtree';
}

ThemeData iziTheme() {
  const scheme = ColorScheme.light(
    primary: IziColors.blue,
    onPrimary: Colors.white,
    secondary: IziColors.cyan,
    onSecondary: IziColors.ink,
    surface: IziColors.surface,
    onSurface: IziColors.ink,
    onSurfaceVariant: IziColors.secondary,
    outline: IziColors.border,
    outlineVariant: IziColors.border,
    error: IziColors.danger,
    onError: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: IziFonts.body,
  );

  const sora = TextStyle(
    fontFamily: IziFonts.display,
    fontWeight: FontWeight.w700,
    color: IziColors.ink,
  );

  return base.copyWith(
    scaffoldBackgroundColor: IziColors.surface,
    textTheme: base.textTheme
        .apply(bodyColor: IziColors.ink, displayColor: IziColors.ink)
        .copyWith(
          headlineSmall: sora.copyWith(fontSize: 24, letterSpacing: -0.5),
          titleLarge: sora.copyWith(fontSize: 20, letterSpacing: -0.3),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: IziColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: IziColors.secondary,
          ),
          bodySmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: IziColors.muted,
          ),
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          labelSmall: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: IziColors.blue,
          ),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: IziColors.surface,
      foregroundColor: IziColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: sora.copyWith(fontSize: 20, letterSpacing: -0.3),
      shape: const Border(bottom: BorderSide(color: IziColors.border)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: IziColors.blue,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: IziColors.ink,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: const TextStyle(
        fontFamily: IziFonts.body,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
```

## lib/models/product.dart

```dart
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
```

## lib/services/product_service.dart

```dart
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
```

## lib/pages/products_page.dart

```dart
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/izi_theme.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, this.service});

  final ProductService? service; // injecté dans les tests

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final _service = widget.service ?? ProductService();

  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  String? _selectedType; // null = tous

  // category -> libellé, dans l'ordre de l'API
  Map<String, String> get _types => {
    for (final p in _products) p.category: p.categoryLabel,
  };

  List<Product> get _visible => _selectedType == null
      ? _products
      : _products.where((p) => p.category == _selectedType).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final products = await _service.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _error = null;
        _loading = false;
        _checkFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _message(e);
        _loading = false;
      });
    }
  }

  Future<void> _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    return _load();
  }

  // Pull-to-refresh : on garde la liste à l'écran, et si ça échoue on prévient
  // juste avec un snackbar.
  Future<void> _refresh() async {
    try {
      final products = await _service.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _checkFilter();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  // si le type filtré n'existe plus après rechargement, retour sur "Tous"
  void _checkFilter() {
    if (!_types.containsKey(_selectedType)) _selectedType = null;
  }

  String _message(Object e) =>
      e is ProductException ? e.message : 'Une erreur inattendue est survenue.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produits')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _retry);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: IziColors.blue,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        key: const ValueKey('products-scroll'),
        // sinon pas de pull-to-refresh quand la liste tient à l'écran
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_products.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: _EmptyView())
          else ...[
            SliverToBoxAdapter(
              child: _Filters(
                types: _types,
                selected: _selectedType,
                count: _visible.length,
                onChanged: (type) => setState(() => _selectedType = type),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount: _visible.length,
                itemBuilder: (_, i) => _ProductCard(_visible[i]),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.types,
    required this.selected,
    required this.count,
    required this.onChanged,
  });

  final Map<String, String> types;
  final String? selected;
  final int count;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _Chip(
        label: 'Tous',
        selected: selected == null,
        onTap: () => onChanged(null),
      ),
      for (final e in types.entries)
        _Chip(
          label: e.value,
          selected: selected == e.key,
          onTap: () => onChanged(e.key),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chips.length,
            itemBuilder: (_, i) => chips[i],
            separatorBuilder: (_, _) => const SizedBox(width: 8),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            count == 1 ? '1 produit' : '$count produits',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? IziColors.gradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: selected ? null : Border.all(color: IziColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : IziColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(this.product);

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IziColors.border),
        boxShadow: [
          BoxShadow(
            color: IziColors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Thumbnail(product.thumbnail),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.category.isNotEmpty) _Tag(product.categoryLabel),
                const SizedBox(height: 6),
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            product.priceLabel,
            style: const TextStyle(
              fontFamily: IziFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: IziColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail(this.url);

  final String url;

  @override
  Widget build(BuildContext context) {
    const placeholder = Center(
      child: Icon(Icons.image_outlined, color: IziColors.muted, size: 26),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 72,
        color: IziColors.surfaceAlt,
        child: url.isEmpty
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: IziColors.blueTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: IziColors.gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: IziColors.blueTint,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: IziColors.blue, size: 30),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _RoundIcon(Icons.cloud_off_rounded),
            const SizedBox(height: 20),
            Text('Impossible de charger', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _GradientButton(
              label: 'Réessayer',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _RoundIcon(Icons.inventory_2_outlined),
            const SizedBox(height: 20),
            Text('Aucun produit pour le moment.', style: text.titleMedium),
            const SizedBox(height: 6),
            Text('Tirez vers le bas pour actualiser.', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
```

## test/products_page_test.dart

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izistacks_products/pages/products_page.dart';
import 'package:izistacks_products/services/product_service.dart';

Map<String, dynamic> product(
  int id,
  String title, [
  String category = 'beauty',
]) => {
  'id': id,
  'title': title,
  'price': 9.99,
  'category': category,
  'thumbnail': 'https://example.com/$id.webp',
};

http.Response ok(List<Map<String, dynamic>> products) => http.Response(
  jsonEncode({'products': products}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Widget app(http.Client client) => MaterialApp(
  home: ProductsPage(service: ProductService(client: client)),
);

Future<void> pullToRefresh(WidgetTester tester) async {
  await tester.fling(
    find.byKey(const ValueKey('products-scroll')),
    const Offset(0, 300),
    1000,
  );
  await tester.pump();
  // le temps que l'indicateur fasse ses animations
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loader puis liste', (tester) async {
    final completer = Completer<http.Response>();
    final client = MockClient((_) => completer.future);

    await tester.pumpWidget(app(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(ok([product(1, 'Mascara'), product(2, 'Palette')]));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Mascara'), findsOneWidget);
    expect(find.text('Palette'), findsOneWidget);
    expect(find.text('\$9.99'), findsNWidgets(2));
  });

  testWidgets('erreur puis retry', (tester) async {
    var calls = 0;
    final retry = Completer<http.Response>();
    final client = MockClient((_) {
      calls++;
      return calls == 1 ? Future.value(http.Response('', 500)) : retry.future;
    });

    await tester.pumpWidget(app(client));
    await tester.pumpAndSettle();

    expect(find.text('Erreur serveur (500).'), findsOneWidget);
    expect(find.text('Mascara'), findsNothing);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    retry.complete(ok([product(1, 'Mascara')]));
    await tester.pumpAndSettle();

    expect(find.text('Mascara'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(calls, 2);
  });

  testWidgets('serveur injoignable', (tester) async {
    final client = MockClient((_) async => throw http.ClientException('down'));

    await tester.pumpWidget(app(client));
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de joindre le serveur. Vérifiez votre connexion.'),
      findsOneWidget,
    );
  });

  testWidgets('pull-to-refresh recharge la liste', (tester) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return ok([product(calls, calls == 1 ? 'Ancien' : 'Nouveau')]);
    });

    await tester.pumpWidget(app(client));
    await tester.pumpAndSettle();
    expect(find.text('Ancien'), findsOneWidget);

    await pullToRefresh(tester);

    expect(calls, 2);
    expect(find.text('Nouveau'), findsOneWidget);
    expect(find.text('Ancien'), findsNothing);
  });

  testWidgets('refresh en échec : la liste reste, snackbar', (tester) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) return ok([product(1, 'Mascara')]);
      throw http.ClientException('down');
    });

    await tester.pumpWidget(app(client));
    await tester.pumpAndSettle();

    await pullToRefresh(tester);

    expect(calls, 2);
    expect(find.text('Mascara'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);

    // sinon flutter_test râle à cause du timer du snackbar
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('filtre par type', (tester) async {
    final client = MockClient(
      (_) async =>
          ok([product(1, 'Mascara'), product(2, 'Canapé', 'furniture')]),
    );

    await tester.pumpWidget(app(client));
    await tester.pumpAndSettle();

    expect(find.text('2 produits'), findsOneWidget);

    await tester.tap(find.text('Furniture'));
    await tester.pumpAndSettle();

    expect(find.text('1 produit'), findsOneWidget);
    expect(find.text('Mascara'), findsNothing);
    expect(find.text('Canapé'), findsOneWidget);

    await tester.tap(find.text('Tous'));
    await tester.pumpAndSettle();

    expect(find.text('Mascara'), findsOneWidget);
    expect(find.text('Canapé'), findsOneWidget);
  });

  testWidgets('liste vide', (tester) async {
    final client = MockClient((_) async => ok([]));

    await tester.pumpWidget(app(client));
    await tester.pumpAndSettle();

    expect(find.text('Aucun produit pour le moment.'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
```

## test/product_test.dart

```dart
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
```
