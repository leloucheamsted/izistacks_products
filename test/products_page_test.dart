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
