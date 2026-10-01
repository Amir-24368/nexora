import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/purchase_order.dart';
import 'models/product.dart';
import 'models/shop.dart';

/// A restock line the user is composing before it becomes a purchase order.
class _RestockItem {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitCost;

  _RestockItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitCost,
  });

  double get subtotal => quantity * unitCost;
}

/// Buy Information / Restocking: pick a supplier, pick products, set the
/// quantity and unit cost, then either park the purchase as a draft or
/// receive it immediately so the stock lands in inventory.
class BuyInfoPage extends StatefulWidget {
  const BuyInfoPage({super.key});

  @override
  State<BuyInfoPage> createState() => _BuyInfoPageState();
}

class _BuyInfoPageState extends State<BuyInfoPage> {
  // ---- loaded data ----
  bool _loading = true;
  List<PurchaseOrder> _orders = [];
  List<Product> _products = [];
  Map<String, int> _stockByProduct = {};
  List<Map<String, dynamic>> _suppliers = [];
  List<Shop> _shops = [];

  // ---- form state ----
  String? _selectedShopId;
  String? _selectedSupplierId;
  String? _selectedProductId;
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expectedDelivery;
  bool _receiveNow = true;
  bool _creating = false;
  final List<_RestockItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ==========================================================
  // DATA LOADING
  // ==========================================================

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);
    try {
      final orders = await ApiService.getPurchaseOrders();
      final products = await ApiService.getProducts();

      List<Shop> shops = [];
      try {
        shops = await ApiService.getShops();
      } catch (_) {
        // Shop list unavailable -- the picker falls back to the
        // server-side default shop.
      }

      List<Map<String, dynamic>> suppliers = [];
      try {
        suppliers = await ApiService.getSuppliers();
      } catch (_) {
        // Restricted roles may not see suppliers; the rest of the page
        // still works for viewing existing purchase orders.
      }

      final Map<String, int> stock = {};
      try {
        final inventory = await ApiService.getInventory();
        for (final row in inventory) {
          final productId = row['product']?.toString();
          if (productId == null) continue;
          final quantity = int.tryParse(row['quantity']?.toString() ?? '') ?? 0;
          final shopKey = row['shop']?.toString() ?? '';
          if (shopKey.isEmpty) {
            stock[productId] = quantity;
          } else {
            // Keyed per shop so multi-shop owners see the right stock.
            stock['${shopKey}_$productId'] = quantity;
          }
        }
      } catch (_) {
        // Inventory endpoint unavailable -- stock hints stay hidden.
      }

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _products = products;
        _suppliers = suppliers;
        _shops = shops;
        // Single-shop accounts get their shop preselected; multi-shop
        // owners pick explicitly.
        _selectedShopId ??= shops.length == 1 ? shops.first.id : null;
        _stockByProduct = stock;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    final message = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ==========================================================
  // FORM
  // ==========================================================

  /// Products visible for the currently selected receiving shop.
  List<Product> get _productsForShop {
    if (_selectedShopId == null) return _products;
    return _products.where((p) => p.shopId == _selectedShopId).toList();
  }

  Product? get _selectedProduct {
    for (final product in _productsForShop) {
      if (product.id == _selectedProductId) return product;
    }
    return null;
  }

  int get _formQuantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  void _onShopSelected(String? shopId) {
    setState(() {
      if (_selectedShopId == shopId) return;
      _selectedShopId = shopId;
      // Products belong to shops -- reset the pick and any composed lines
      // so products from another shop can't slip into the purchase.
      _selectedProductId = null;
      _costController.clear();
      _items.clear();
    });
  }

  void _onProductSelected(String? productId) {
    setState(() {
      _selectedProductId = productId;
      final product = _selectedProduct;
      if (product != null && product.purchasePrice > 0) {
        _costController.text = product.purchasePrice.toStringAsFixed(2);
      }
    });
  }

  void _addItem() {
    final product = _selectedProduct;
    if (product == null) {
      _showError('Select a product to restock');
      return;
    }
    final quantity = int.tryParse(_quantityController.text.trim());
    final unitCost = double.tryParse(_costController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showError('Enter a quantity greater than zero');
      return;
    }
    if (unitCost == null || unitCost <= 0) {
      _showError('Enter a valid unit cost');
      return;
    }

    setState(() {
      final existingIndex = _items.indexWhere((item) => item.productId == product.id);
      if (existingIndex >= 0) {
        // Same product added twice -> merge into one line.
        final existing = _items[existingIndex];
        _items[existingIndex] = _RestockItem(
          productId: existing.productId,
          productName: existing.productName,
          sku: existing.sku,
          quantity: existing.quantity + quantity,
          unitCost: unitCost,
        );
      } else {
        _items.add(_RestockItem(
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          quantity: quantity,
          unitCost: unitCost,
        ));
      }
      _selectedProductId = null;
      _quantityController.clear();
      _costController.clear();
    });
  }

  double get _orderTotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _pickDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDelivery ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _expectedDelivery = picked);
    }
  }

  Future<void> _createPurchase() async {
    if (_selectedShopId == null) {
      _showError('Select which shop receives the stock');
      return;
    }
    if (_selectedSupplierId == null) {
      _showError('Select a supplier');
      return;
    }
    if (_items.isEmpty) {
      _showError('Add at least one product to the purchase');
      return;
    }

    setState(() => _creating = true);
    try {
      final payload = <String, dynamic>{
        'shop': _selectedShopId,
        'supplier': _selectedSupplierId,
        if (_expectedDelivery != null) 'expected_delivery': _formatDate(_expectedDelivery!),
        'notes': _notesController.text.trim(),
        'lines': _items
            .map((item) => {
                  'product': item.productId,
                  'quantity': item.quantity,
                  'purchase_price': item.unitCost,
                })
            .toList(),
      };

      var order = await ApiService.createPurchaseOrder(payload);

      if (_receiveNow) {
        // Receive immediately: approve, then check the whole order in so the
        // stock actually lands in inventory (draft orders do not add stock).
        order = await ApiService.approvePurchaseOrder(order.id);
        final receivedLines = order.lines
            .where((line) => line.remaining > 0)
            .map((line) => {'line_id': line.id, 'quantity': line.remaining})
            .toList();
        if (receivedLines.isNotEmpty) {
          order = await ApiService.receivePurchaseOrder(order.id, receivedLines);
        }
      }

      if (!mounted) return;
      setState(() {
        _items.clear();
        _selectedProductId = null;
        _quantityController.clear();
        _costController.clear();
        _notesController.clear();
        _expectedDelivery = null;
        _creating = false;
      });
      _showSuccess(
        _receiveNow
            ? 'Restock complete — ${order.totalReceived} units added to inventory'
            : 'Purchase order #${order.id} saved as draft',
      );
      await _loadData();
    } catch (e) {
      if (mounted) setState(() => _creating = false);
      _showError(e);
    }
  }

  // ==========================================================
  // ORDER ACTIONS
  // ==========================================================

  Future<void> _approveOrder(PurchaseOrder order) async {
    try {
      await ApiService.approvePurchaseOrder(order.id);
      _showSuccess('Purchase order #${order.id} approved');
      await _loadData();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _receiveOrder(PurchaseOrder order) async {
    final lines = order.lines
        .where((line) => line.remaining > 0)
        .map((line) => {'line_id': line.id, 'quantity': line.remaining})
        .toList();
    if (lines.isEmpty) {
      _showError('Nothing left to receive on this order');
      return;
    }
    try {
      final updated = await ApiService.receivePurchaseOrder(order.id, lines);
      _showSuccess('Received ${updated.totalReceived} units — inventory updated');
      await _loadData();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _cancelOrder(PurchaseOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel purchase order #${order.id}?'),
        content: const Text('The order will be marked as cancelled and can no longer be received.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.cancelPurchaseOrder(order.id);
      _showSuccess('Purchase order #${order.id} cancelled');
      await _loadData();
    } catch (e) {
      _showError(e);
    }
  }

  // ==========================================================
  // NEW SUPPLIER DIALOG
  // ==========================================================

  Future<void> _showAddSupplierDialog() async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Supplier'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Supplier name *'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(labelText: 'Contact person'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => saving = true);
                      try {
                        final created = await ApiService.createSupplier({
                          'name': nameController.text.trim(),
                          'contact_person': contactController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'email': emailController.text.trim(),
                        });
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        await _loadData();
                        final newId = created['id']?.toString();
                        if (mounted && newId != null) {
                          setState(() => _selectedSupplierId = newId);
                        }
                        _showSuccess('Supplier added');
                      } catch (e) {
                        setDialogState(() => saving = false);
                        _showError(e);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Buy Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 950;
                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: SingleChildScrollView(child: _buildRestockForm())),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: _buildOrdersList()),
                      ],
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildRestockForm(),
                    const SizedBox(height: 20),
                    SizedBox(height: 420, child: _buildOrdersList()),
                  ],
                );
              },
            ),
    );
  }

  // ----------------------------------------------------------
  // LEFT: restock form
  // ----------------------------------------------------------

  Widget _buildRestockForm() {
    final selected = _selectedProduct;
    final stockKey = selected == null
        ? null
        : (_selectedShopId != null ? '${_selectedShopId}_${selected.id}' : selected.id);
    final currentStock = stockKey != null ? (_stockByProduct[stockKey] ?? 0) : 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_business_outlined, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Restock Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(
                        'Buy stock from a supplier and add it to inventory',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---- Receiving shop ----
            DropdownButtonFormField<String>(
              value: _selectedShopId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Receiving shop *',
                border: OutlineInputBorder(),
              ),
              hint: Text(_shops.isEmpty
                  ? 'Loading shops…'
                  : 'Which shop gets this stock?'),
              items: _shops
                  .map((shop) => DropdownMenuItem<String>(
                        value: shop.id,
                        child: Text(shop.name, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: _onShopSelected,
            ),
            const SizedBox(height: 16),

            // ---- Supplier ----
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSupplierId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Supplier *',
                      border: OutlineInputBorder(),
                    ),
                    hint: Text(_suppliers.isEmpty ? 'No suppliers yet — add one' : 'Select supplier'),
                    items: _suppliers
                        .map((supplier) => DropdownMenuItem<String>(
                              value: supplier['id']?.toString(),
                              child: Text(supplier['name'] ?? 'Supplier', overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedSupplierId = value),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Add a new supplier',
                  child: IconButton.filledTonal(
                    onPressed: _showAddSupplierDialog,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Product ----
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Product *',
                border: OutlineInputBorder(),
              ),
              hint: Text(
                  _selectedShopId == null
                      ? 'Pick a shop first'
                      : _productsForShop.isEmpty
                          ? 'No products in this shop yet'
                          : 'Select product to restock'),
              items: _productsForShop
                  .map((product) => DropdownMenuItem<String>(
                        value: product.id,
                        child: Text(
                          '${product.name}${product.sku.isNotEmpty ? ' · ${product.sku}' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: _onProductSelected,
            ),
            if (selected != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Current stock: $currentStock'
                    '${_formQuantity > 0 ? '  →  after restock: ${currentStock + _formQuantity}' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // ---- Quantity + unit cost ----
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Unit cost *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add product to purchase'),
              ),
            ),

            // ---- Items list ----
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 4),
              const Text('Purchase items', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._items.map(_buildItemRow),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    _money(_orderTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // ---- Optional details ----
            InkWell(
              onTap: _pickDeliveryDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expected delivery (optional)',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  _expectedDelivery != null ? _formatDate(_expectedDelivery!) : 'Not set',
                  style: TextStyle(color: _expectedDelivery != null ? Colors.black87 : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _receiveNow,
              onChanged: (value) => setState(() => _receiveNow = value),
              title: const Text('Receive stock now', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Adds the items to inventory immediately',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _creating ? null : _createPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                icon: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_receiveNow ? 'Buy & add to stock' : 'Create purchase order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(_RestockItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.quantity} × ${_money(item.unitCost)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(_money(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Remove',
            onPressed: () => setState(() => _items.remove(item)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // RIGHT: purchase orders
  // ----------------------------------------------------------

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No purchase orders yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text('Create your first restock on the left', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
    );
  }

  String _shopName(String? shopId) {
    if (shopId == null) return '';
    for (final shop in _shops) {
      if (shop.id == shopId) return shop.name;
    }
    return '';
  }

  Widget _buildOrderCard(PurchaseOrder order) {
    final canApprove = order.status == 'DRAFT';
    final canReceive = order.status == 'APPROVED' ||
        order.status == 'ORDERED' ||
        order.status == 'PARTIALLY_RECEIVED';
    final canCancel = order.status != 'RECEIVED' && order.status != 'CANCELLED';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          order.supplierName.isEmpty ? 'Purchase order #${order.id}' : order.supplierName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'PO #${order.id}'
            '${_shopName(order.shopId).isEmpty ? '' : ' · → ${_shopName(order.shopId)}'}'
            ' · ${order.lines.length} product${order.lines.length == 1 ? '' : 's'}'
            ' · ${_formatDate(order.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statusChip(order.status),
            const SizedBox(height: 4),
            Text(_money(order.total), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        children: [
          for (final line in order.lines) _buildLineRow(line),
          if (order.lines.isNotEmpty &&
              (order.status == 'PARTIALLY_RECEIVED' || order.status == 'RECEIVED')) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: order.totalOrdered == 0 ? 0 : order.totalReceived / order.totalOrdered,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
              minHeight: 6,
            ),
          ],
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Notes: ${order.notes}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
          if (canApprove || canReceive || canCancel) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canApprove)
                  TextButton.icon(
                    onPressed: () => _approveOrder(order),
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    label: const Text('Approve'),
                  ),
                if (canReceive)
                  FilledButton.icon(
                    onPressed: () => _receiveOrder(order),
                    icon: const Icon(Icons.move_to_inbox_outlined, size: 16),
                    label: Text(order.status == 'PARTIALLY_RECEIVED' ? 'Receive remaining' : 'Receive all'),
                  ),
                if (canCancel)
                  TextButton(
                    onPressed: () => _cancelOrder(order),
                    child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineRow(PurchaseOrderLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName.isEmpty ? 'Product #${line.productId}' : line.productName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Ordered ${line.orderedQuantity} · Received ${line.receivedQuantity} · ${_money(line.purchasePrice)}/unit',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(_money(line.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    late final Color color;
    late final String label;
    switch (status) {
      case 'DRAFT':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'SUBMITTED':
        color = Colors.amber.shade700;
        label = 'Submitted';
        break;
      case 'APPROVED':
        color = Colors.blue;
        label = 'Approved';
        break;
      case 'ORDERED':
        color = Colors.indigo;
        label = 'Ordered';
        break;
      case 'PARTIALLY_RECEIVED':
        color = Colors.orange;
        label = 'Partial';
        break;
      case 'RECEIVED':
        color = Colors.green;
        label = 'Received';
        break;
      case 'CANCELLED':
        color = Colors.redAccent;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
