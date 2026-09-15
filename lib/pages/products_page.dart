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
