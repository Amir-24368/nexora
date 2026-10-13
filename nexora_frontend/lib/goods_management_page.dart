import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/product.dart';
import 'models/category.dart';
import 'models/shop.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class GoodsManagementPage extends StatefulWidget {
  const GoodsManagementPage({super.key});

  @override
  State<GoodsManagementPage> createState() => _GoodsManagementPageState();
}

class _GoodsManagementPageState extends State<GoodsManagementPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Category> categories = [];
  List<Shop> shops = [];
  bool isLoading = true;
  String error = '';
  final _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _taxPercentageController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _reorderPointController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedShopId;
  String? _selectedVolumeFrom;
  String? _selectedVolumeTo;
  String _selectedStatus = 'ACTIVE';
  bool _trackInventory = true;
  bool _isActive = true;
  String? _editingProductId;

  static const List<String> _volumeOptions = [
    '100ml',
    '250ml',
    '500ml',
    '750ml',
    '1L',
    '2L',
    '5L',
    '10L',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _discountPercentageController.dispose();
    _taxPercentageController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _reorderPointController.dispose();
    super.dispose();
  }

  void _filter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      filteredProducts = products.where((p) {
        if (query.isEmpty) return true;
        return p.name.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            (p.brand?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) setState(() => isLoading = true);
    try {
      final prods = await ApiService.getProducts();
      final cats = await ApiService.getCategoriesTree();
      final shopsList = await ApiService.getShops();
      if (!mounted) return;
      setState(() {
        products = prods;
        categories = cats;
        shops = shopsList;
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

  void _showProductDialog({Product? product}) {
    _editingProductId = product?.id;
    if (product != null) {
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _brandController.text = product.brand ?? '';
      _descriptionController.text = product.description ?? '';
      _purchasePriceController.text = product.purchasePrice.toString();
      _salePriceController.text = product.salePrice.toString();
      _discountPercentageController.text = product.discountPercentage?.toString() ?? '';
      _taxPercentageController.text = product.taxPercentage.toString();
      _selectedVolumeFrom = _volumeOptions.contains(product.volumeFrom) ? product.volumeFrom : 'Other';
      _selectedVolumeTo = _volumeOptions.contains(product.volumeTo) ? product.volumeTo : 'Other';
      _dateFromController.text = product.dateFrom;
      _dateToController.text = product.dateTo;
      _selectedShopId = product.shop?.id;
      _weightController.text = product.weight?.toString() ?? '';
      _lengthController.text = product.length?.toString() ?? '';
      _widthController.text = product.width?.toString() ?? '';
      _heightController.text = product.height?.toString() ?? '';
      _minStockController.text = product.minimumStock.toString();
      _maxStockController.text = product.maximumStock.toString();
      _reorderPointController.text = product.reorderPoint.toString();
      _selectedCategoryId = product.category?.id;
      _selectedStatus = product.status;
      _trackInventory = product.trackInventory;
      _isActive = product.isActive;
    } else {
      _nameController.clear();
      _skuController.clear();
      _brandController.clear();
      _descriptionController.clear();
      _purchasePriceController.clear();
      _salePriceController.clear();
      _discountPercentageController.clear();
      _taxPercentageController.clear();
      _selectedVolumeFrom = null;
      _selectedVolumeTo = null;
      _dateFromController.clear();
      _dateToController.clear();
      _selectedShopId = null;
      _weightController.clear();
      _lengthController.clear();
      _widthController.clear();
      _heightController.clear();
      _minStockController.clear();
      _maxStockController.clear();
      _reorderPointController.clear();
      _selectedCategoryId = null;
      _selectedStatus = 'ACTIVE';
      _trackInventory = true;
      _isActive = true;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final flatCategories = _flattenCategoriesUnique(categories);
          final palette = nxOf(dialogContext);

          Widget section(String title) => Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  children: [
                    Container(width: 3, height: 14, decoration: BoxDecoration(color: palette.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text(title.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: palette.textMuted)),
                  ],
                ),
              );

          return nxDialog(
            context: dialogContext,
            title: _editingProductId == null ? 'Add product' : 'Edit product',
            content: SizedBox(
              width: 520,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      section('Basic information'),
                      NxTextField(controller: _nameController, label: 'Product name *', hint: 'e.g., Wireless Headphones', maxLength: 255, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: NxTextField(controller: _skuController, label: 'SKU *', hint: 'Unique ID (e.g. WH-001)', maxLength: 100, validator: (v) => v!.trim().isEmpty ? 'SKU is required' : null)),
                        const SizedBox(width: 10),
                        Expanded(child: NxTextField(controller: _brandController, label: 'Brand', hint: 'e.g., Sony, Apple')),
                      ]),
                      const SizedBox(height: 10),
                      NxTextField(controller: _descriptionController, label: 'Description', hint: 'Product details…', maxLines: 3, maxLength: 1000),

                      section('Classification'),
                      _categoryDropdown(setDialogState, flatCategories),

                      section('Pricing'),
                      Row(children: [
                        Expanded(child: NxTextField(controller: _purchasePriceController, label: 'Purchase price *', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v!.isEmpty ? 'Required' : null)),
                        const SizedBox(width: 10),
                        Expanded(child: NxTextField(controller: _salePriceController, label: 'Sale price *', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v!.isEmpty ? 'Required' : null)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: NxTextField(controller: _discountPercentageController, label: 'Discount %', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final d = double.tryParse(v);
                          if (d == null) return 'Enter a number';
                          if (d < 0 || d > 100) return 'Must be 0-100';
                          return null;
                        })),
                        const SizedBox(width: 10),
                        Expanded(child: NxTextField(controller: _taxPercentageController, label: 'Tax %', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ]),

                      section('Volume & date'),
                      Row(children: [
                        Expanded(child: _volumeDropdown(setDialogState, value: _selectedVolumeFrom, label: 'Volume from', onChanged: (val) => setDialogState(() => _selectedVolumeFrom = val))),
                        const SizedBox(width: 10),
                        Expanded(child: _volumeDropdown(setDialogState, value: _selectedVolumeTo, label: 'Volume to', onChanged: (val) => setDialogState(() => _selectedVolumeTo = val))),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _dateField(setDialogState, controller: _dateFromController)),
                        const SizedBox(width: 10),
                        Expanded(child: _dateField(setDialogState, controller: _dateToController)),
                      ]),

                      section('Source / shop'),
                      _shopDropdown(setDialogState),

                      section('Physical dimensions'),
                      Row(children: [
                        Expanded(child: NxTextField(controller: _weightController, label: 'Weight (kg)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 10),
                        Expanded(child: NxTextField(controller: _lengthController, label: 'Length (cm)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: NxTextField(controller: _widthController, label: 'Width (cm)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 10),
                        Expanded(child: NxTextField(controller: _heightController, label: 'Height (cm)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ]),

                      section('Inventory'),
                      Row(children: [
                        Expanded(child: NxTextField(controller: _minStockController, label: 'Min stock', keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: NxTextField(controller: _maxStockController, label: 'Max stock', keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 10),
                      NxTextField(controller: _reorderPointController, label: 'Reorder point', hint: 'Stock level that triggers reorder', keyboardType: TextInputType.number),

                      section('Status'),
                      _statusDropdown(setDialogState),
                      NxSwitchRow(title: 'Track inventory', subtitle: 'Enable to track stock levels', value: _trackInventory, onToggle: (v) => setDialogState(() => _trackInventory = v)),
                      NxSwitchRow(title: 'Visible in store', subtitle: 'Product appears in the shopfront', value: _isActive, onToggle: (v) => setDialogState(() => _isActive = v)),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              NxButton(label: 'Cancel', variant: NxButtonVariant.ghost, onPressed: () => Navigator.pop(dialogContext)),
              NxButton(label: _editingProductId == null ? 'Add' : 'Update', onPressed: _saveProduct),
            ],
          );
        },
      ),
    );
  }

  Widget _statusDropdown(StateSetter setDialogState) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
        DropdownMenuItem(value: 'DISCONTINUED', child: Text('Discontinued')),
      ],
      onChanged: (val) => setDialogState(() => _selectedStatus = val ?? 'ACTIVE'),
      decoration: _dropdownDecoration('Status'),
    );
  }

  Widget _categoryDropdown(StateSetter setDialogState, List<Category> flatCategories) {
    final palette = nxOf(context);
    if (flatCategories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: palette.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.border)),
        child: Text('No categories yet — create one in Categories first', style: TextStyle(fontSize: 13, color: palette.textMuted)),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      isExpanded: true,
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('None')),
        ...flatCategories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (val) => setDialogState(() => _selectedCategoryId = val),
      decoration: _dropdownDecoration('Category'),
    );
  }

  Widget _volumeDropdown(StateSetter setDialogState, {required String? value, required String label, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: _volumeOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
      decoration: _dropdownDecoration(label),
    );
  }

  Widget _shopDropdown(StateSetter setDialogState) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedShopId,
      isExpanded: true,
      items: shops.map((shop) => DropdownMenuItem<String>(value: shop.id, child: Text(shop.name, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (val) => setDialogState(() => _selectedShopId = val),
      decoration: _dropdownDecoration('Source *'),
      validator: (val) => val == null ? 'Please select a shop' : null,
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    final palette = nxOf(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.primary, width: 1.4)),
      labelStyle: TextStyle(color: palette.textMuted, fontSize: 14),
    );
  }

  Widget _dateField(StateSetter setDialogState, {required TextEditingController controller}) {
    final palette = nxOf(context);
    final hasValue = controller.text.trim().isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          setDialogState(() => controller.text = date.toIso8601String().split('T')[0]);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.border)),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: palette.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? controller.text : 'Tap to select',
                style: TextStyle(fontSize: 14, color: hasValue ? palette.textPrimary : palette.textMuted.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Category> _flattenCategoriesUnique(List<Category> cats) {
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final volumeFrom = _selectedVolumeFrom ?? '';
      final volumeTo = _selectedVolumeTo ?? '';

      final data = {
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim(),
        'brand': _brandController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategoryId,
        'purchase_price': double.parse(_purchasePriceController.text),
        'sale_price': double.parse(_salePriceController.text),
        'discount_percentage': _discountPercentageController.text.isNotEmpty
            ? double.parse(_discountPercentageController.text)
            : null,
        'tax_percentage': double.tryParse(_taxPercentageController.text) ?? 0,
        'volume_from': volumeFrom,
        'volume_to': volumeTo,
        // Backend DateFields reject empty strings -- send null instead.
        'date_from': _dateFromController.text.trim().isNotEmpty ? _dateFromController.text.trim() : null,
        'date_to': _dateToController.text.trim().isNotEmpty ? _dateToController.text.trim() : null,
        'shop': _selectedShopId,
        'weight': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        'length': _lengthController.text.isNotEmpty ? double.parse(_lengthController.text) : null,
        'width': _widthController.text.isNotEmpty ? double.parse(_widthController.text) : null,
        'height': _heightController.text.isNotEmpty ? double.parse(_heightController.text) : null,
        'minimum_stock': int.tryParse(_minStockController.text) ?? 0,
        'maximum_stock': int.tryParse(_maxStockController.text) ?? 0,
        'reorder_point': int.tryParse(_reorderPointController.text) ?? 0,
        'status': _selectedStatus,
        'is_active': _isActive,
        'track_inventory': _trackInventory,
      };

      if (_editingProductId == null) {
        await ApiService.createProduct(data);
      } else {
        await ApiService.updateProduct(_editingProductId!, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      await _loadData(showSpinner: false);
      if (!mounted) return;
      nxSnack(context, _editingProductId == null ? 'Product added' : 'Product updated');
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      if (errorMsg.startsWith('Network error: ')) {
        errorMsg = errorMsg.substring(14);
      }
      if (errorMsg.contains('IntegrityError') ||
          errorMsg.contains('unique') ||
          errorMsg.contains('already exists') ||
          errorMsg.contains('duplicate') ||
          errorMsg.toLowerCase().contains('sku')) {
        errorMsg = 'A product with this SKU already exists.';
      } else if (errorMsg.contains('shop')) {
        errorMsg = 'Invalid shop selected.';
      }
      if (!mounted) return;
      nxSnack(context, errorMsg, isError: true);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await nxConfirm(
      context,
      title: 'Delete product',
      message: 'Delete "${product.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      variant: NxButtonVariant.danger,
    );
    if (!confirmed) return;
    try {
      await ApiService.deleteProduct(product.id);
      await _loadData(showSpinner: false);
      if (!mounted) return;
      nxSnack(context, 'Product deleted');
    } catch (e) {
      if (!mounted) return;
      nxSnack(context, 'Delete failed: $e', isError: true);
    }
  }

  // =======================================================================
  // BUILD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    final list = filteredProducts;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Goods Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: palette.primary,
        foregroundColor: palette.textOnAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New product'),
      ),
      body: isLoading
          ? const NxLoader(label: 'Loading products…')
          : error.isNotEmpty
              ? NxErrorView(message: error, onRetry: () => _loadData())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: NxTextField(controller: _searchController, hint: 'Search name, SKU or brand…', prefixIcon: Icons.search_rounded),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? NxEmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: products.isEmpty ? 'No products yet' : 'No matches',
                              message: products.isEmpty ? 'Add your first product to start selling.' : 'Try a different search term.',
                              actionLabel: products.isEmpty ? 'New product' : null,
                              onAction: products.isEmpty ? () => _showProductDialog() : null,
                            )
                          : RefreshIndicator(
                              color: palette.primary,
                              onRefresh: () => _loadData(showSpinner: false),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 760;
                                  return ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                                    itemCount: list.length,
                                    itemBuilder: (_, i) => wide ? _productRow(list[i]) : _productCard(list[i]),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _productCard(Product p) {
    final palette = nxOf(context);
    final effective = p.effectivePrice;
    final hasDiscount = p.discountPercentage != null && p.discountPercentage! > 0;
    return NxCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => _showProductDialog(product: p),
      child: Row(
        children: [
          NxIconBlock(icon: Icons.inventory_2_outlined, color: palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                const SizedBox(height: 3),
                Text('SKU ${p.sku} · ${p.brand ?? 'No brand'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: palette.textMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text('\$${p.salePrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 12.5, color: palette.textMuted, decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 6),
                    ],
                    Text('\$${effective.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: palette.success)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NxBadge(text: p.isActive ? p.status : 'Inactive', variant: nxStatusVariant(p.isActive ? p.status : 'inactive')),
          const SizedBox(width: 4),
          NxIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete', color: palette.danger, onTap: () => _deleteProduct(p)),
        ],
      ),
    );
  }

  Widget _productRow(Product p) {
    final palette = nxOf(context);
    return NxCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => _showProductDialog(product: p),
      child: Row(
        children: [
          NxIconBlock(icon: Icons.inventory_2_outlined, color: palette.primary, size: 44),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                Text('SKU ${p.sku}  ·  ${p.shop?.name ?? 'No shop'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: palette.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${p.brand ?? '—'}  ·  Vol ${p.volumeFrom}${p.volumeTo.isNotEmpty && p.volumeTo != p.volumeFrom ? ' → ${p.volumeTo}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: palette.textMuted),
            ),
          ),
          SizedBox(
            width: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$${p.effectivePrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: palette.success)),
                Text('Purchase \$${p.purchasePrice.toStringAsFixed(2)}  ·  Tax ${p.taxPercentage}%', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: palette.textMuted)),
              ],
            ),
          ),
          NxBadge(text: p.isActive ? p.status : 'Inactive', variant: nxStatusVariant(p.isActive ? p.status : 'inactive')),
          const SizedBox(width: 10),
          NxIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', onTap: () => _showProductDialog(product: p)),
          NxIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete', color: palette.danger, onTap: () => _deleteProduct(p)),
        ],
      ),
    );
  }
}

/// Theme-styled switch row used inside dialogs.
class NxSwitchRow extends StatelessWidget {
  const NxSwitchRow({super.key, required this.title, required this.subtitle, required this.value, required this.onToggle});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: palette.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: palette.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onToggle(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? palette.primary : palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
