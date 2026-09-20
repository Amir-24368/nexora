import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/purchase_order.dart';

class BuyInfoPage extends StatefulWidget {
  const BuyInfoPage({super.key});

  @override
  State<BuyInfoPage> createState() => _BuyInfoPageState();
}

class _BuyInfoPageState extends State<BuyInfoPage> {
  List<PurchaseOrder> orders = [];
  List<dynamic> products = [];
  List<Map<String, dynamic>> suppliers = [];
  String? _selectedProductId;
  String? _selectedSupplierId;
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid ScaffoldMessenger error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final ordersData = await ApiService.getPurchaseOrders();
      final productsData = await ApiService.getProducts();
      List<Map<String, dynamic>> suppliersData = [];
      try {
        suppliersData = await ApiService.getSuppliers();
      } catch (_) {
        // Suppliers endpoint may be unavailable for restricted roles; the
        // page still works for viewing existing purchase orders.
      }
      if (!mounted) return;
      setState(() {
        orders = ordersData;
        products = productsData.map((p) => p.toJson()).toList();
        suppliers = suppliersData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addPurchase() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supplier'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product'), backgroundColor: Colors.red),
      );
      return;
    }

    final qty = int.tryParse(_quantityController.text);
    final cost = double.tryParse(_costController.text);
    if (qty == null || qty <= 0 || cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid quantity and cost required'), backgroundColor: Colors.red),
      );
      return;
    }

    // Payload matches the backend PurchaseOrderViewSet: supplier + nested lines.
    final poData = {
      'supplier': _selectedSupplierId,
      'lines': [
        {
          'product': _selectedProductId,
          'quantity': qty,
          'purchase_price': cost,
        }
      ],
    };

    try {
      await ApiService.createPurchaseOrder(poData);
      await _loadData();
      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase order added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add purchase order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedProductId = null;
      _quantityController.clear();
      _costController.clear();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedSupplierId,
                    hint: const Text('Select Supplier'),
                    items: suppliers.map((s) => DropdownMenuItem<String>(
                      value: s['id'].toString(),
                      child: Text(s['name'] ?? 'Supplier'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedSupplierId = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    hint: const Text('Select Product'),
                    items: products.map((p) => DropdownMenuItem<String>(
                      value: p['id'].toString(),
                      child: Text(p['name'] ?? ''),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v),
                  ),
                  TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _costController,
                    decoration: const InputDecoration(labelText: 'Cost per unit'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addPurchase,
                    child: const Text('Add Purchase Order'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: orders.isEmpty
                ? const Center(child: Text('No purchase orders'))
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (_, i) {
                      final po = orders[i];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(po.supplierName.isEmpty ? 'Purchase Order #${po.id}' : po.supplierName),
                          subtitle: Text('Status: ${po.status} | Subtotal: \$${po.subtotal.toStringAsFixed(2)} | Total: \$${po.total.toStringAsFixed(2)}'),
                          trailing: Text(po.createdAt.toLocal().toString().split(' ')[0]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}