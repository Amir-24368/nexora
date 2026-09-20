import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/product.dart';
import 'models/category.dart';
import 'user_cart_manager.dart';
import 'product_detail_page.dart';

class UserShoppingPage extends StatefulWidget {
  const UserShoppingPage({super.key});

  @override
  State<UserShoppingPage> createState() => _UserShoppingPageState();
}

class _UserShoppingPageState extends State<UserShoppingPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Category> categories = [];
  String? _selectedCategoryId;
  final searchController = TextEditingController();
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    searchController.addListener(_filter);
  }

  Future<void> _loadData() async {
    try {
      final prods = await ApiService.getProducts();
      final cats = await ApiService.getCategoriesTree();
      setState(() {
        products = prods;
        filteredProducts = List.from(products);
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
      filteredProducts = products.where((p) {
        bool matchesSearch = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
        bool matchesCategory = _selectedCategoryId == null ||
            p.category?.id == _selectedCategoryId;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _addToCart(Product p) {
    CartManager().addItem(p);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${p.name} to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text('Error: $error'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
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
          child: filteredProducts.isEmpty
              ? const Center(child: Text('No products found'))
              : ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (_, i) {
                    final p = filteredProducts[i];
                    final effectivePrice = p.effectivePrice;
                    final hasDiscount = p.discountPercentage != null && p.discountPercentage! > 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(product: p),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image),
                            ),
                            title: Text(p.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SKU: ${p.sku}'),
                                Text('Category: ${p.category?.name ?? 'Uncategorized'}'),
                                Row(
                                  children: [
                                    if (hasDiscount)
                                      Text(
                                        '\$${p.salePrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '\$${effectivePrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: hasDiscount ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                              onPressed: () => _addToCart(p),
                            ),
                          ),
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