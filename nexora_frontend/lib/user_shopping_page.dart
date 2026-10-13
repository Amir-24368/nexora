import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/product.dart';
import 'models/category.dart';
import 'user_cart_manager.dart';
import 'product_detail_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prods = await ApiService.getProducts();
      final cats = await ApiService.getCategoriesTree();
      if (!mounted) return;
      setState(() {
        products = prods.where((p) => p.isActive).toList();
        filteredProducts = List.from(products);
        categories = cats;
        isLoading = false;
        error = '';
      });
      _filter();
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
    nxSnack(context, 'Added ${p.name} to cart');
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);

    if (isLoading) return const NxLoader(label: 'Loading products…');
    if (error.isNotEmpty) {
      return NxErrorView(message: error, onRetry: _loadData);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            children: [
              NxTextField(
                controller: searchController,
                hint: 'Search products…',
                prefixIcon: Icons.search_rounded,
              ),
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
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? NxEmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: products.isEmpty ? 'Nothing in the store yet' : 'No matches',
                  message: products.isEmpty
                      ? 'Check back soon — the shop is being stocked.'
                      : 'Try a different search or category.',
                )
              : RefreshIndicator(
                  color: palette.primary,
                  onRefresh: _loadData,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 620
                              ? 2
                              : 1;
                      if (columns == 1) {
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: filteredProducts.length,
                          itemBuilder: (_, i) => _productCard(filteredProducts[i]),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.4,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (_, i) => _productCard(filteredProducts[i]),
                      );
                    },
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

  Widget _productCard(Product p) {
    final palette = nxOf(context);
    final effectivePrice = p.effectivePrice;
    final hasDiscount = p.discountPercentage != null && p.discountPercentage! > 0;

    return NxCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailPage(product: p)),
        );
      },
      child: Row(
        children: [
          NxIconBlock(icon: Icons.shopping_bag_outlined, color: palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${p.brand ?? p.category?.name ?? 'General'} · SKU ${p.sku}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text('\$${p.salePrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: palette.textMuted, decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 6),
                      NxBadge(text: '-${p.discountPercentage!.toStringAsFixed(0)}%', variant: NxBadgeVariant.danger),
                      const SizedBox(width: 6),
                    ],
                    Text('\$${effectivePrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: palette.success)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NxIconButton(
            icon: Icons.add_shopping_cart_rounded,
            tooltip: 'Add to cart',
            color: palette.primary,
            onTap: () => _addToCart(p),
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
