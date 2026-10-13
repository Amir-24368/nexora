import 'package:flutter/material.dart';
import 'models/customer.dart';
import 'models/sale.dart';
import 'services/api_service.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  List<Sale> sales = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      final data = await ApiService.getSales(customerId: widget.customer.id);
      setState(() {
        sales = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) nxSnack(context, 'Failed to load orders: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    final c = widget.customer;
    final totalOrders = sales.length;
    final avgOrder = totalOrders > 0 ? c.totalSpent / totalOrders : 0;
    final completedOrders = sales.where((s) => s.status == 'COMPLETED').length;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: Text(c.fullName),
      ),
      body: loading
          ? const NxLoader(label: 'Loading profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero card with avatar + contact.
                  NxCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: nxHeroGradient),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c.fullName.trim().isNotEmpty
                                ? c.fullName.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join()
                                : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.fullName, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                              const SizedBox(height: 2),
                              Text(c.email ?? 'No email', style: TextStyle(fontSize: 13, color: palette.textMuted)),
                              const SizedBox(height: 2),
                              Text('Phone: ${c.phone.isNotEmpty ? c.phone : '-'}', style: TextStyle(fontSize: 13, color: palette.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _Stat(label: 'Total spent', value: '\$${c.totalSpent.toStringAsFixed(2)}', color: palette.success)),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat(label: 'Total orders', value: totalOrders.toString(), color: palette.info)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _Stat(label: 'Average order', value: '\$${avgOrder.toStringAsFixed(2)}', color: palette.warning)),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat(label: 'Completed', value: completedOrders.toString(), color: palette.primary)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  NxSectionHeader(title: 'Order history', subtitle: '${sales.length} order(s) on record'),
                  if (sales.isEmpty)
                    const NxEmptyState(icon: Icons.receipt_long_outlined, title: 'No orders yet', message: 'Orders this customer places will show up here.')
                  else
                    ...sales.map((s) => NxCard(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const NxIconBlock(icon: Icons.shopping_bag_rounded, color: Color(0xFF7C3AED), size: 44),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order #${s.id}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text('${_date(s.saleDate)} · ${s.items.length} item(s)', style: TextStyle(fontSize: 12.5, color: palette.textMuted)),
                                  ],
                                ),
                              ),
                              NxBadge(text: s.status, variant: nxStatusVariant(s.status)),
                              const SizedBox(width: 10),
                              Text('\$${s.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                            ],
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  String _date(DateTime d) => d.toLocal().toString().split(' ')[0];
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return NxCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: palette.textMuted)),
          const SizedBox(height: 6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
