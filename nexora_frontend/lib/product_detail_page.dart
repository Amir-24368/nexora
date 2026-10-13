import 'package:flutter/material.dart';
import 'models/product.dart';
import 'user_cart_manager.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    final hasDiscount = product.discountPercentage != null && product.discountPercentage! > 0;
    final displayPrice = product.effectivePrice;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Image hero (placeholder until images upload) ----
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [palette.primarySoft, palette.surface],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(Icons.image_outlined, size: 72, color: palette.textMuted),
                ),
                const SizedBox(height: 20),

                Text(
                  product.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: palette.textPrimary, letterSpacing: -0.3),
                ),
                if (product.brand != null && product.brand!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(product.brand!, style: TextStyle(fontSize: 15, color: palette.textMuted)),
                ],
                const SizedBox(height: 10),

                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text('\$${product.salePrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: palette.textMuted, decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 8),
                      NxBadge(text: '-${product.discountPercentage!.toStringAsFixed(0)}%', variant: NxBadgeVariant.danger),
                      const SizedBox(width: 8),
                    ],
                    Text('\$${displayPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: palette.success)),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Spec sheet ----
                NxCard(
                  child: Column(
                    children: [
                      _specRow(Icons.tag_rounded, 'SKU', product.sku, palette),
                      _specRow(Icons.category_outlined, 'Category', product.category?.name ?? 'Uncategorized', palette),
                      if (product.volumeFrom.isNotEmpty || product.volumeTo.isNotEmpty)
                        _specRow(Icons.local_drink_outlined, 'Volume', '${product.volumeFrom} → ${product.volumeTo}', palette),
                      if (product.dateFrom.isNotEmpty || product.dateTo.isNotEmpty)
                        _specRow(Icons.calendar_today_outlined, 'Available', '${product.dateFrom} → ${product.dateTo}', palette),
                      if (product.source.isNotEmpty)
                        _specRow(Icons.storefront_outlined, 'Source', product.source, palette),
                      _specRow(
                        Icons.inventory_outlined,
                        'Stock tracking',
                        product.trackInventory ? 'Enabled' : 'Disabled',
                        palette,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (product.description != null && product.description!.trim().isNotEmpty) ...[
                  NxCard(
                    child: Text(
                      product.description!,
                      style: TextStyle(fontSize: 14.5, height: 1.55, color: palette.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ---- Add to cart ----
                SizedBox(
                  width: double.infinity,
                  child: NxButton(
                    label: 'Add to cart',
                    icon: Icons.add_shopping_cart_rounded,
                    height: 52,
                    onPressed: () {
                      CartManager().addItem(product);
                      nxSnack(context, 'Added ${product.name} to cart');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _specRow(IconData icon, String label, String value, NxTheme palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: palette.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: palette.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
