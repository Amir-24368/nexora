import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'logout_helper.dart';
import 'models/product.dart';
import 'models/category.dart';
import 'models/shop.dart';

class GoodsManagementPage extends StatefulWidget {
  const GoodsManagementPage({super.key});

  @override
  State<GoodsManagementPage> createState() => _GoodsManagementPageState();
}

class _GoodsManagementPageState extends State<GoodsManagementPage> {
  List<Product> products = [];
  List<Category> categories = [];
  List<Shop> shops = [];
  bool isLoading = true;
  String error = '';

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
  File? _selectedImage;

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
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final prods = await ApiService.getProducts();
      final cats = await ApiService.getCategoriesTree();
      final shopsList = await ApiService.getShops();

      print('✅ Loaded ${prods.length} products');
      print('✅ Loaded ${cats.length} categories');
      print('✅ Loaded ${shopsList.length} shops');

      setState(() {
        products = prods;
        categories = cats;
        shops = shopsList;
        isLoading = false;
        error = '';
      });
    } catch (e) {
      print('❌ Error loading data: $e');
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
      _selectedImage = null;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final flatCategories = _flattenCategoriesUnique(categories);

          return AlertDialog(
            title: Text(_editingProductId == null ? 'Add Product' : 'Edit Product'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    const Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        hintText: 'e.g., Wireless Headphones',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 255,
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU *',
                        hintText: 'Unique identifier (e.g., WH-001)',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 100,
                      validator: (v) => v!.trim().isEmpty ? 'SKU is required' : null,
                    ),
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        hintText: 'e.g., Sony, Apple, Samsung',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Product details...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 1000,
                    ),

                    const SizedBox(height: 16),

                    // Classification
                    const Text('Classification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      hint: const Text('Category'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...flatCategories.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        )),
                      ],
                      onChanged: (val) => setDialogState(() => _selectedCategoryId = val),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pricing
                    const Text('Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceController,
                            decoration: const InputDecoration(
                              labelText: 'Purchase Price *',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _salePriceController,
                            decoration: const InputDecoration(
                              labelText: 'Sale Price *',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountPercentageController,
                            decoration: const InputDecoration(
                              labelText: 'Discount %',
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final d = double.tryParse(v);
                              if (d == null) return 'Enter a number';
                              if (d < 0 || d > 100) return 'Must be between 0 and 100';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _taxPercentageController,
                            decoration: const InputDecoration(
                              labelText: 'Tax %',
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Volume & Date
                    const Text('Volume & Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedVolumeFrom,
                            hint: const Text('Volume From'),
                            items: _volumeOptions.map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v),
                            )).toList(),
                            onChanged: (val) => setDialogState(() => _selectedVolumeFrom = val),
                            decoration: const InputDecoration(
                              labelText: 'Volume From',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedVolumeTo,
                            hint: const Text('Volume To'),
                            items: _volumeOptions.map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v),
                            )).toList(),
                            onChanged: (val) => setDialogState(() => _selectedVolumeTo = val),
                            decoration: const InputDecoration(
                              labelText: 'Volume To',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dateFromController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date From',
                              hintText: 'Tap to select',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setDialogState(() {
                                  _dateFromController.text = date.toIso8601String().split('T')[0];
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _dateToController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date To',
                              hintText: 'Tap to select',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setDialogState(() {
                                  _dateToController.text = date.toIso8601String().split('T')[0];
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Source / Shop
                    const Text('Source / Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedShopId,
                      hint: const Text('Select Shop'),
                      items: shops.map((shop) => DropdownMenuItem<String>(
                        value: shop.id,
                        child: Text(shop.name),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => _selectedShopId = val),
                      decoration: const InputDecoration(
                        labelText: 'Source *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null ? 'Please select a shop' : null,
                    ),

                    const SizedBox(height: 16),

                    // Physical Dimensions
                    const Text('Physical Dimensions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _lengthController,
                            decoration: const InputDecoration(
                              labelText: 'Length (cm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _widthController,
                            decoration: const InputDecoration(
                              labelText: 'Width (cm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Inventory
                    const Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minStockController,
                            decoration: const InputDecoration(
                              labelText: 'Min Stock',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _maxStockController,
                            decoration: const InputDecoration(
                              labelText: 'Max Stock',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _reorderPointController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Point',
                        hintText: 'Stock level that triggers reorder',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // Status
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                        DropdownMenuItem(value: 'DISCONTINUED', child: Text('Discontinued')),
                      ],
                      onChanged: (val) => setDialogState(() => _selectedStatus = val!),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Track Inventory'),
                      subtitle: const Text('Enable to track stock levels'),
                      value: _trackInventory,
                      onChanged: (val) => setDialogState(() => _trackInventory = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Product visible in store'),
                      value: _isActive,
                      onChanged: (val) => setDialogState(() => _isActive = val),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),

                    // Image
                    const Text('Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _selectedImage == null
                              ? const Text('No image selected')
                              : Text('Selected: ${_selectedImage!.path.split('/').last}'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (result != null && result.files.single.path != null) {
                              setDialogState(() {
                                _selectedImage = File(result.files.single.path!);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(_editingProductId == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Category> _flattenCategoriesUnique(List<Category> cats) {
    final result = <Category>[];
    final ids = <String>{};
    void traverse(List<Category> nodes) {
      for (var cat in nodes) {
        if (!ids.contains(cat.id)) {
          ids.add(cat.id);
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

      print('📦 Sending product data: $data');

      if (_editingProductId == null) {
        await ApiService.createProduct(data);
      } else {
        await ApiService.updateProduct(_editingProductId!, data);
      }
      Navigator.pop(context);
      // Refresh the list
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingProductId == null ? 'Product added' : 'Product updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error saving product: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProduct(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteProduct(id);
                Navigator.pop(context);
                await _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Delete failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goods Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // close the dialog first
                        performLogout(context);            // then logout with the page's own context
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : products.isEmpty
                  ? const Center(child: Text('No products'))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (_, i) {
                        final p = products[i];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(p.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SKU: ${p.sku}'),
                                Text('Brand: ${p.brand ?? 'N/A'}'),
                                Text('Price: \$${p.salePrice} | Active: ${p.isActive ? 'Yes' : 'No'}'),
                                if (p.volumeFrom.isNotEmpty || p.volumeTo.isNotEmpty)
                                  Text('Volume: ${p.volumeFrom} → ${p.volumeTo}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showProductDialog(product: p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteProduct(p.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}