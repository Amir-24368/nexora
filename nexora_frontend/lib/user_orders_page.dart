import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/sale.dart';
import 'models/category.dart';

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
      final cats = await ApiService.getCategoriesTree();
      setState(() {
        sales = data;
        filteredSales = List.from(sales);
        categories = cats;
        isLoading = false;
      });
    } catch (e) {
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

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'RETURNED':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text('Error: $error'));
    if (sales.isEmpty) return const Center(child: Text('No orders yet'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search orders...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                hint: const Text('All Categories'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ..._flattenCategories(categories).map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }),
                ],
                onChanged: (val) => setState(() {
                  _selectedCategoryId = val;
                  _filter();
                }),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                isExpanded: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredSales.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.builder(
                  itemCount: filteredSales.length,
                  itemBuilder: (_, i) {
                    final s = filteredSales[i];
                    final itemCount =
                        s.items.fold<int>(0, (sum, item) => sum + item.quantity);
                    final firstName = s.items.isNotEmpty
                        ? (s.items.first.product?.name ?? 'Item')
                        : 'No items';
                    final moreCount = s.items.length - 1;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.receipt_long),
                          ),
                          title: Text('Order #${s.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                moreCount > 0
                                    ? '$itemCount item(s): $firstName +$moreCount more'
                                    : '$itemCount item(s): $firstName',
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(s.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  s.status,
                                  style: TextStyle(
                                    color: _statusColor(s.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${s.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(s.saleDate.toLocal().toString().split(' ')[0]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Category> _flattenCategories(List<Category> cats) {
    List<Category> result = [];
    for (var cat in cats) {
      result.add(cat);
      result.addAll(_flattenCategories(cat.children));
    }
    return result;
  }
}