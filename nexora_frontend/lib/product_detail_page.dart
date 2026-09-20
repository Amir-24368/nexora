import 'package:flutter/material.dart';
import 'models/product.dart';
import 'user_cart_manager.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPercentage != null && product.discountPercentage! > 0;
    final displayPrice = product.effectivePrice;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (product.brand != null && product.brand!.isNotEmpty)
              Text(
                product.brand!,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text('SKU: ${product.sku}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Category: ${product.category?.name ?? 'Uncategorized'}',
              style: const TextStyle(fontSize: 16),
            ),
            if (product.volumeFrom.isNotEmpty || product.volumeTo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Volume: ${product.volumeFrom} → ${product.volumeTo}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (product.dateFrom.isNotEmpty || product.dateTo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Date: ${product.dateFrom} → ${product.dateTo}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (product.source.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Source: ${product.source}', style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 8),
            Text(
              'Stock Tracking: ${product.trackInventory ? 'Enabled' : 'Disabled'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasDiscount)
                  Text(
                    '\$${product.salePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '\$${displayPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: hasDiscount ? Colors.red : Colors.green,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${product.discountPercentage!.toStringAsFixed(0)}% off)',
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  CartManager().addItem(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${product.name} to cart')),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}