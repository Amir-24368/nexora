import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/sale.dart';

class SaleInfoPage extends StatefulWidget {
  const SaleInfoPage({super.key});

  @override
  State<SaleInfoPage> createState() => _SaleInfoPageState();
}

class _SaleInfoPageState extends State<SaleInfoPage> {
  List<Sale> sales = [];
  bool isLoading = true;
  String error = '';
  final Set<String> _expandedKeys = {}; // which product rows are expanded

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      final data = await ApiService.getSales();
      setState(() {
        sales = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text('Error: $error'));

    final totalRevenue = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final merged = _mergeByProduct(sales); // one entry per product

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('Total Orders', sales.length.toString(), Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Total Revenue', '\$${totalRevenue.toStringAsFixed(2)}', Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: sales.isEmpty
                ? const Center(child: Text('No sales yet'))
                : ListView.builder(
                    itemCount: merged.length,
                    itemBuilder: (_, i) {
                      final p = merged[i];
                      final isExpanded = _expandedKeys.contains(p.key);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ListTile(
                                onTap: () => setState(() {
                                  isExpanded
                                      ? _expandedKeys.remove(p.key)
                                      : _expandedKeys.add(p.key);
                                }),
                            leading: Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.inventory_2),
                            ),
                            title: Text(p.name,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p.buyers.length} buyer(s) · ${p.units} unit(s) sold'),
                                const SizedBox(height: 4),
                                Text(
                                  'Since ${p.firstSale != null ? p.firstSale!.toLocal().toString().split(' ')[0] : '-'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${p.revenue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${p.orders} order(s)',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                              ),
                              if (isExpanded)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const Text('Purchase history',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      ...p.lines.map(
                                        (l) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Order #${l.orderId} · ${l.buyer} · ${l.date.toLocal().toString().split(' ')[0]}',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                              Text(
                                                '${l.qty} × ${l.price.toStringAsFixed(2)} = ${l.lineTotal.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Merges all order lines into one summary per product:
  /// unique buyers, total revenue in dollars, units sold,
  /// how many orders contained it, and the first purchase date.
  List<_ProductSummary> _mergeByProduct(List<Sale> allSales) {
    final Map<String, _ProductSummary> byProduct = {};
    for (final sale in allSales) {
      final buyerKey = sale.customer != null
          ? (sale.customer!.id.isNotEmpty
              ? sale.customer!.id
              : 'c:${sale.customer!.fullName}')
          : 'guest';
      for (final item in sale.items) {
        final key = item.product?.id ?? 'unknown:${item.id}';
        final summary = byProduct.putIfAbsent(
          key,
          () => _ProductSummary(key: key, name: item.product?.name ?? 'Unknown product'),
        );
        summary.lines.add(_SaleLine(
          orderId: sale.id,
          buyer: sale.customer?.fullName ?? 'Guest',
          date: sale.saleDate,
          qty: item.quantity,
          price: item.price,
        ));
        summary.revenue += item.price * item.quantity;
        summary.units += item.quantity;
        summary.orders += 1;
        summary.buyers.add(buyerKey);
        if (summary.firstSale == null || sale.saleDate.isBefore(summary.firstSale!)) {
          summary.firstSale = sale.saleDate;
        }
      }
    }
    final list = byProduct.values.toList();
    list.sort((a, b) => b.revenue.compareTo(a.revenue)); // best sellers first
    return list;
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSummary {
  final String key;
  final String name;
  double revenue = 0;
  int units = 0;
  int orders = 0;
  final Set<String> buyers = {};
  final List<_SaleLine> lines = [];
  DateTime? firstSale;

  _ProductSummary({required this.key, required this.name});
}

class _SaleLine {
  final String orderId;
  final String buyer;
  final DateTime date;
  final int qty;
  final double price;
  double get lineTotal => price * qty;

  _SaleLine({
    required this.orderId,
    required this.buyer,
    required this.date,
    required this.qty,
    required this.price,
  });
}