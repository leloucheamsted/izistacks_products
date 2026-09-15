// Captures des différents écrans, pour vérifier le rendu sans lancer l'app.
// Skippé par défaut :
//   flutter test --dart-define=SCREENSHOT_DIR=/tmp/shots test/screenshot_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izistacks_products/pages/products_page.dart';
import 'package:izistacks_products/services/product_service.dart';
import 'package:izistacks_products/theme/izi_theme.dart';

const enabled = bool.hasEnvironment('SCREENSHOT_DIR');
const outDir = String.fromEnvironment('SCREENSHOT_DIR');

Future<void> loadFonts() async {
  final fonts = {
    'Sora': 'assets/fonts/Sora-Variable.ttf',
    'Figtree': 'assets/fonts/Figtree-Variable.ttf',
  };
  for (final e in fonts.entries) {
    await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
  }
}

Future<void> capture(WidgetTester tester, Key key, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Map<String, dynamic> product(int id, String title, double price, String cat) =>
    {
      'id': id,
      'title': title,
      'price': price,
      'category': cat,
      'thumbnail': '',
    };

void main() {
  testWidgets('captures', skip: !enabled, (tester) async {
    await loadFonts();
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final products = [
      product(1, 'Essence Mascara Lash Princess', 9.99, 'beauty'),
      product(2, 'Eyeshadow Palette with Mirror', 19.99, 'beauty'),
      product(3, 'Calvin Klein CK One', 49.99, 'fragrances'),
      product(4, 'Annibale Colombo Bed', 1899.99, 'furniture'),
      product(
        5,
        'Knoll Saarinen Executive Conference Chair',
        499.99,
        'furniture',
      ),
      product(6, 'Apple', 1.99, 'groceries'),
      product(7, 'Decoration Swing', 59.99, 'home-decoration'),
      product(8, 'Family Tree Photo Frame', 29.99, 'home-decoration'),
    ];

    var fail = false;
    final client = MockClient((_) async {
      if (fail) throw http.ClientException('down');
      return http.Response(
        jsonEncode({'products': products}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    const key = ValueKey('shot');
    Widget app() => RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: iziTheme(),
        home: ProductsPage(service: ProductService(client: client)),
      ),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await capture(tester, key, 'list');

    await tester.tap(find.text('Furniture'));
    await tester.pumpAndSettle();
    await capture(tester, key, 'filtered');

    fail = true;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await capture(tester, key, 'error');
  });
}
