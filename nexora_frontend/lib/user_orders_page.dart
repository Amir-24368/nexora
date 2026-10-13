import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/sale.dart';
import 'models/category.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  List<Sale> sales = [];
  List<Sale> filteredSales = [];
  List<Category> categories = [];
  String? _selectedCategoryId;
  final searchController = TextEditingController();
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
    searchController.addListener(_filter);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      // 'mine' filters by the logged-in user's email on the backend,
      // so customers only see their own orders.
      final data = await ApiService.getSales(mine: true);
      if (!mounted) return;
      setState(() {
        sales = data;
        filteredSales = List.from(sales);
        categories = [];
        isLoading = false;
        error = '';
      });
      _filter();
      try {
        final cats = await ApiService.getCategoriesTree();
        if (!mounted) return;
        setState(() => categories = cats);
      } catch (_) {
        // Category filter is optional — orders still show without it.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _filter() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredSales = sales.where((s) {
        final itemNames = s.items.map((i) => i.product?.name ?? '').join(' ').toLowerCase();
        final matchesSearch = query.isEmpty ||
            s.id.toLowerCase().contains(query) ||
            s.status.toLowerCase().contains(query) ||
            itemNames.contains(query);
        final matchesCategory = _selectedCategoryId == null ||
            s.items.any((i) => i.product?.category?.id == _selectedCategoryId);
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);

    if (isLoading) return const NxLoader(label: 'Loading your orders…');
    if (error.isNotEmpty) {
      return NxErrorView(message: error, onRetry: _loadOrders);
    }
    if (sales.isEmpty) {
      return NxEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Everything you buy will show up here.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            children: [
              NxTextField(
                controller: searchController,
                hint: 'Search orders…',
                prefixIcon: Icons.search_rounded,
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  hint: const Text('All categories'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ..._flattenCategories(categories).map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedCategoryId = val;
                    _filter();
                  }),
                  decoration: _ddDecoration(),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: filteredSales.isEmpty
              ? const Center(child: Text('No orders found'))
              : RefreshIndicator(
                  color: palette.primary,
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: filteredSales.length,
                    itemBuilder: (_, i) => _orderCard(filteredSales[i]),
                  ),
                ),
        ),
      ],
    );
  }

  InputDecoration _ddDecoration() {
    final palette = nxOf(context);
    return InputDecoration(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.primary, width: 1.4)),
    );
  }

  Widget _orderCard(Sale s) {
    final palette = nxOf(context);
    final itemCount = s.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final firstName = s.items.isNotEmpty ? (s.items.first.product?.name ?? 'Item') : 'No items';
    final moreCount = s.items.length - 1;

    return NxCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          NxIconBlock(icon: Icons.receipt_long_outlined, color: palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${s.id.length > 8 ? s.id.substring(0, 8) : s.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                      ),
                    ),
                    NxBadge(text: s.status, variant: nxStatusVariant(s.status)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  moreCount > 0 ? '$itemCount item(s): $firstName +$moreCount more' : '$itemCount item(s): $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('\$${s.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: palette.success)),
                    const Spacer(),
                    Text(s.saleDate.toLocal().toString().split(' ')[0], style: TextStyle(fontSize: 12, color: palette.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Flattens the category tree for the dropdown. The API returns a flat
  /// list where children ALSO appear nested in their parent, so the same
  /// category can be reached twice -- dedupe by id or DropdownButton
  /// crashes with "multiple items with the same value".
  List<Category> _flattenCategories(List<Category> cats) {
    final result = <Category>[];
    final ids = <String>{};
    void traverse(List<Category> nodes) {
      for (var cat in nodes) {
        if (ids.add(cat.id)) {
          result.add(cat);
        }
        if (cat.children.isNotEmpty) {
          traverse(cat.children);
        }
      }
    }
    traverse(cats);
    return result;
  }
}
