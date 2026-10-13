import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/sale.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

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
    final palette = nxOf(context);
    final merged = _mergeByProduct(sales); // one entry per product
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Sales'),
      ),
      body: isLoading
          ? const NxLoader(label: 'Loading sales...')
          : error.isNotEmpty
              ? NxErrorView(message: error, onRetry: _loadSales)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total orders',
                              value: sales.length.toString(),
                              icon: Icons.receipt_long_rounded,
                              color: palette.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Total revenue',
                              value: '\$${sales.fold(0.0, (sum, s) => sum + s.totalAmount).toStringAsFixed(2)}',
                              icon: Icons.payments_rounded,
                              color: palette.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: merged.isEmpty
                          ? const NxEmptyState(
                              icon: Icons.ssid_chart_rounded,
                              title: 'No sales yet',
                              message: 'Recorded sales will appear here as customers check out.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                              itemCount: merged.length,
                              itemBuilder: (_, i) {
                                final p = merged[i];
                                final isExpanded = _expandedKeys.contains(p.key);
                                return _ProductCard(
                                  summary: p,
                                  expanded: isExpanded,
                                  onToggle: () => setState(() {
                                    isExpanded ? _expandedKeys.remove(p.key) : _expandedKeys.add(p.key);
                                  }),
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
          ? (sale.customer!.id.isNotEmpty ? sale.customer!.id : 'c:${sale.customer!.fullName}')
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return NxCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          NxIconBlock(icon: icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textMuted)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: palette.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.summary, required this.expanded, required this.onToggle});
  final _ProductSummary summary;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return NxCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onToggle,
      child: Column(
        children: [
          Row(
            children: [
              const NxIconBlock(icon: Icons.inventory_2_rounded, color: Color(0xFF7C3AED), size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${summary.buyers.length} buyer(s) · ${summary.units} unit(s) sold', style: TextStyle(fontSize: 12.5, color: palette.textMuted)),
                    if (summary.firstSale != null) ...[
                      const SizedBox(height: 2),
                      Text('Since ${_date(summary.firstSale!)}', style: TextStyle(fontSize: 11.5, color: palette.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${summary.revenue.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: palette.success)),
                  Text('${summary.orders} order(s)', style: TextStyle(fontSize: 11.5, color: palette.textMuted)),
                ],
              ),
              Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20, color: palette.textMuted),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('PURCHASE HISTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: palette.textMuted)),
            ),
            const SizedBox(height: 4),
            ...summary.lines.map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${l.orderId} · ${l.buyer} · ${_date(l.date)}',
                          style: TextStyle(fontSize: 12, color: palette.textMuted),
                        ),
                      ),
                      Text(
                        '${l.qty} × ${l.price.toStringAsFixed(2)} = ${l.lineTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textPrimary),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _date(DateTime d) => d.toLocal().toString().split(' ')[0];
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
