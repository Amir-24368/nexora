import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'cart_page.dart';

class Product {
  String id;
  String cid;
  String cName;
  String volumeFrom;
  String volumeTo;
  String dateFrom;
  String dateTo;
  String description;
  String category;
  String brand;
  String uom;
  String tag;
  String? imagePath;
  double price;
  double? offPrice;

  Product({
    required this.id,
    required this.cid,
    required this.cName,
    required this.volumeFrom,
    required this.volumeTo,
    required this.dateFrom,
    required this.dateTo,
    required this.description,
    required this.category,
    required this.brand,
    required this.uom,
    required this.tag,
    this.imagePath,
    required this.price,
    this.offPrice,
  });

  double get effectivePrice => offPrice != null && offPrice! < price ? offPrice! : price;
}

class ShoppingPage extends StatefulWidget {
  final VoidCallback onLogout;
  const ShoppingPage({super.key, required this.onLogout});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];

  final searchController = TextEditingController();

  final cidController = TextEditingController();
  final cNameController = TextEditingController();
  final priceController = TextEditingController();
  final offPriceController = TextEditingController();

  String? selectedVolumeFrom;
  String? selectedVolumeTo;
  String? fromYear, fromMonth, fromDay;
  String? toYear, toMonth, toDay;
  String? selectedImagePath;
  String? editingId;

  List<String> volumeOptions = [
    '100ml', '200ml', '250ml', '500ml', '750ml', '1L', '1.5L', '2L',
    '100g', '200g', '250g', '500g', '1kg', '2kg', '5kg',
    '1 Piece', '2 Pieces', '5 Pieces', '10 Pieces'
  ];

  List<String> years = List.generate(21, (i) => (2020 + i).toString());
  List<String> months = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
  List<String> days = List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();

    products.addAll([
      Product(
        id: '1', cid: '12345', cName: 'Laptop',
        volumeFrom: '2kg', volumeTo: '3kg',
        dateFrom: '2025-01-01', dateTo: '2025-12-31',
        description: '', category: 'Electronics', brand: 'Dell', uom: 'Piece', tag: 'New',
        price: 899.99, offPrice: 799.99,
      ),
      Product(
        id: '2', cid: '67890', cName: 'T-Shirt',
        volumeFrom: '150g', volumeTo: '250g',
        dateFrom: '2025-03-01', dateTo: '2025-09-30',
        description: '', category: 'Clothing', brand: 'Nike', uom: 'Piece', tag: 'Sale',
        price: 19.99, offPrice: 14.99,
      ),
      Product(
        id: '3', cid: '11111', cName: 'Phone',
        volumeFrom: '200g', volumeTo: '300g',
        dateFrom: '2025-05-01', dateTo: '2025-08-15',
        description: '', category: 'Electronics', brand: 'Samsung', uom: 'Piece', tag: 'New',
        price: 499.99, offPrice: null,
      ),
    ]);

    filteredProducts = List.from(products);
    searchController.addListener(_applyFilters);
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => selectedImagePath = result.files.single.path);
    }
  }

  void _applyFilters() {
    final searchText = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        return searchText.isEmpty ||
            product.cName.toLowerCase().contains(searchText) ||
            product.cid.contains(searchText) ||
            product.volumeFrom.toLowerCase().contains(searchText) ||
            product.volumeTo.toLowerCase().contains(searchText) ||
            product.dateFrom.contains(searchText) ||
            product.dateTo.contains(searchText);
      }).toList();
    });
  }

  void _clearForm() {
    cidController.clear();
    cNameController.clear();
    priceController.clear();
    offPriceController.clear();
    selectedVolumeFrom = null;
    selectedVolumeTo = null;
    fromYear = fromMonth = fromDay = null;
    toYear = toMonth = toDay = null;
    selectedImagePath = null;
    editingId = null;
  }

  String _buildDateFrom() => (fromYear != null && fromMonth != null && fromDay != null) ? '$fromYear-$fromMonth-$fromDay' : '';
  String _buildDateTo() => (toYear != null && toMonth != null && toDay != null) ? '$toYear-$toMonth-$toDay' : '';

  void _save() {
    final cidText = cidController.text.trim();
    if (cidText.isEmpty || !RegExp(r'^\d{5}$').hasMatch(cidText)) {
      _showSnackBar('CID must be a 5-digit code');
      return;
    }
    if (cNameController.text.trim().isEmpty) {
      _showSnackBar('C-name cannot be empty');
      return;
    }
    double? price = double.tryParse(priceController.text.trim());
    if (price == null || price <= 0) {
      _showSnackBar('Enter a valid price');
      return;
    }
    double? offPrice;
    if (offPriceController.text.trim().isNotEmpty) {
      offPrice = double.tryParse(offPriceController.text.trim());
      if (offPrice == null) {
        _showSnackBar('Off price must be a valid number or left empty');
        return;
      }
      if (offPrice >= price) {
        _showSnackBar('Off price must be lower than original price');
        return;
      }
    }

    final volumeFrom = selectedVolumeFrom ?? '';
    final volumeTo = selectedVolumeTo ?? '';
    final dateFrom = _buildDateFrom();
    final dateTo = _buildDateTo();

    setState(() {
      if (editingId == null) {
        products.add(Product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cid: cidText,
          cName: cNameController.text.trim(),
          volumeFrom: volumeFrom,
          volumeTo: volumeTo,
          dateFrom: dateFrom,
          dateTo: dateTo,
          description: '',
          category: '',
          brand: '',
          uom: '',
          tag: '',
          imagePath: selectedImagePath,
          price: price,
          offPrice: offPrice,
        ));
      } else {
        final index = products.indexWhere((p) => p.id == editingId);
        products[index].cid = cidText;
        products[index].cName = cNameController.text.trim();
        products[index].volumeFrom = volumeFrom;
        products[index].volumeTo = volumeTo;
        products[index].dateFrom = dateFrom;
        products[index].dateTo = dateTo;
        products[index].imagePath = selectedImagePath;
        products[index].price = price;
        products[index].offPrice = offPrice;
      }
      _applyFilters();
      _clearForm();
      Navigator.pop(context);
    });
  }

  void _edit(Product p) {
    cidController.text = p.cid;
    cNameController.text = p.cName;
    priceController.text = p.price.toString();
    offPriceController.text = p.offPrice?.toString() ?? '';
    selectedVolumeFrom = volumeOptions.contains(p.volumeFrom) ? p.volumeFrom : null;
    selectedVolumeTo = volumeOptions.contains(p.volumeTo) ? p.volumeTo : null;

    if (p.dateFrom.isNotEmpty && p.dateFrom.contains('-')) {
      final parts = p.dateFrom.split('-');
      if (parts.length == 3) {
        fromYear = years.contains(parts[0]) ? parts[0] : null;
        fromMonth = months.contains(parts[1]) ? parts[1] : null;
        fromDay = days.contains(parts[2]) ? parts[2] : null;
      }
    } else { fromYear = fromMonth = fromDay = null; }
    if (p.dateTo.isNotEmpty && p.dateTo.contains('-')) {
      final parts = p.dateTo.split('-');
      if (parts.length == 3) {
        toYear = years.contains(parts[0]) ? parts[0] : null;
        toMonth = months.contains(parts[1]) ? parts[1] : null;
        toDay = days.contains(parts[2]) ? parts[2] : null;
      }
    } else { toYear = toMonth = toDay = null; }

    selectedImagePath = p.imagePath;
    editingId = p.id;
    _openDialog();
  }

  void _delete(String id) {
    setState(() {
      products.removeWhere((p) => p.id == id);
      _applyFilters();
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildDateDropdownRow(String label, {
    required String? year, required String? month, required String? day,
    required Function(String?) onYearChange,
    required Function(String?) onMonthChange,
    required Function(String?) onDayChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: year, hint: const Text('Year'),
              items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: onYearChange,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            )),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: month, hint: const Text('Month'),
              items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: onMonthChange,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            )),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: day, hint: const Text('Day'),
              items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: onDayChange,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            )),
          ],
        ),
      ],
    );
  }

  void _openDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Product'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: cidController, decoration: const InputDecoration(labelText: 'CID (5-digit)'), keyboardType: TextInputType.number, maxLength: 5),
                    TextField(controller: cNameController, decoration: const InputDecoration(labelText: 'C-name')),
                    TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (\$)'), keyboardType: TextInputType.number),
                    TextField(controller: offPriceController, decoration: const InputDecoration(labelText: 'Off Price (\$) (optional)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    const Text('Volume Range', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(children: [
                      Expanded(child: DropdownButtonFormField<String>(
                        initialValue: selectedVolumeFrom, hint: const Text('From'),
                        items: volumeOptions.map((vol) => DropdownMenuItem(value: vol, child: Text(vol))).toList(),
                        onChanged: (v) => setDialogState(() => selectedVolumeFrom = v),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: DropdownButtonFormField<String>(
                        initialValue: selectedVolumeTo, hint: const Text('To'),
                        items: volumeOptions.map((vol) => DropdownMenuItem(value: vol, child: Text(vol))).toList(),
                        onChanged: (v) => setDialogState(() => selectedVolumeTo = v),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    _buildDateDropdownRow('Date From', year: fromYear, month: fromMonth, day: fromDay, onYearChange: (v) => setDialogState(() => fromYear = v), onMonthChange: (v) => setDialogState(() => fromMonth = v), onDayChange: (v) => setDialogState(() => fromDay = v)),
                    const SizedBox(height: 12),
                    _buildDateDropdownRow('Date To', year: toYear, month: toMonth, day: toDay, onYearChange: (v) => setDialogState(() => toYear = v), onMonthChange: (v) => setDialogState(() => toMonth = v), onDayChange: (v) => setDialogState(() => toDay = v)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async { await _pickImage(); setDialogState(() {}); },
                      child: Container(
                        height: 120, width: double.infinity,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                        child: selectedImagePath != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(selectedImagePath!), fit: BoxFit.cover, width: double.infinity))
                          : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade600), const SizedBox(height: 4), Text('Tap to add image', style: TextStyle(color: Colors.grey.shade600))])),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () { _clearForm(); Navigator.pop(context); }, child: const Text('Cancel')),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          );
        },
      ),
    );
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartPage(products: products)),
    );
  }

  void _addToCart(Product product) {
    CartManager().addItem(product);
    _showSnackBar('Added to cart: ${product.cName}');
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { widget.onLogout(); }, child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // BACK BUTTON
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.shopping_bag, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Goods Information',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: _goToCart,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products by name, CID, volume, date...',
                          prefixIcon: const Icon(Icons.search, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No products found', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (_, i) {
                            final p = filteredProducts[i];
                            final hasOff = p.offPrice != null && p.offPrice! < p.price;
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: InkWell(
                                onTap: () => _edit(p),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: p.imagePath != null
                                            ? Image.file(File(p.imagePath!), width: 80, height: 80, fit: BoxFit.cover)
                                            : Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.cName,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('CID: ${p.cid}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Text('${p.volumeFrom} → ${p.volumeTo}', style: const TextStyle(fontSize: 13)),
                                            Text('${p.dateFrom} → ${p.dateTo}', style: const TextStyle(fontSize: 13)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                if (hasOff)
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 8),
                                                    child: Text(
                                                      '\$${p.price.toStringAsFixed(2)}',
                                                      style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 14),
                                                    ),
                                                  ),
                                                Text(
                                                  '\$${p.effectivePrice.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: hasOff ? Colors.red : Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _edit(p),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _delete(p.id),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                                            onPressed: () => _addToCart(p),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}