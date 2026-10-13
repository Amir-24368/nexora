import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/purchase_order.dart';
import 'models/product.dart';
import 'models/shop.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

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
  String _error = '';
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
        _error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    final message = e.toString().replaceFirst('Exception: ', '');
    nxSnack(context, message, isError: true);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    nxSnack(context, message);
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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

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
      nxSnack(
        context,
        _receiveNow
            ? 'Restock complete — ${order.totalReceived} units added to inventory'
            : 'Purchase order saved as draft',
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
      _showSuccess('Purchase order approved');
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
    final confirmed = await nxConfirm(
      context,
      title: 'Cancel purchase order?',
      message: 'The order will be marked as cancelled and can no longer be received.',
      confirmLabel: 'Cancel order',
      variant: NxButtonVariant.danger,
    );
    if (!confirmed) return;
    try {
      await ApiService.cancelPurchaseOrder(order.id);
      _showSuccess('Purchase order cancelled');
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
        builder: (dialogContext, setDialogState) => nxDialog(
          context: dialogContext,
          title: 'New supplier',
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NxTextField(
                  controller: nameController,
                  label: 'Supplier name *',
                  autofocus: true,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 10),
                NxTextField(controller: contactController, label: 'Contact person'),
                const SizedBox(height: 10),
                NxTextField(controller: phoneController, label: 'Phone'),
                const SizedBox(height: 10),
                NxTextField(
                  controller: emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            NxButton(
              label: 'Cancel',
              variant: NxButtonVariant.ghost,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            NxButton(
              label: 'Save supplier',
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
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Purchasing'),
      ),
      body: _loading
          ? const NxLoader(label: 'Loading purchasing data…')
          : _error.isNotEmpty && _orders.isEmpty && _products.isEmpty
              ? NxErrorView(message: _error, onRetry: _loadData)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 950;
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildRestockForm())),
                          Expanded(flex: 3, child: Padding(padding: const EdgeInsets.fromLTRB(0, 20, 20, 20), child: _buildOrdersList())),
                        ],
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
    final palette = nxOf(context);
    final selected = _selectedProduct;
    final stockKey = selected == null
        ? null
        : (_selectedShopId != null ? '${_selectedShopId}_${selected.id}' : selected.id);
    final currentStock = stockKey != null ? (_stockByProduct[stockKey] ?? 0) : 0;

    return NxCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NxIconBlock(icon: Icons.add_business_outlined, color: palette.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Restock store', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                    Text('Buy stock from a supplier and add it to inventory', style: TextStyle(fontSize: 12.5, color: palette.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---- Receiving shop ----
          DropdownButtonFormField<String>(
            initialValue: _selectedShopId,
            isExpanded: true,
            decoration: _dd(label: 'Receiving shop *'),
            hint: Text(_shops.isEmpty ? 'Loading shops…' : 'Which shop gets this stock?', style: TextStyle(color: palette.textMuted, fontSize: 14)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSupplierId,
                  isExpanded: true,
                  decoration: _dd(label: 'Supplier *'),
                  hint: Text(_suppliers.isEmpty ? 'No suppliers yet — add one' : 'Select supplier', style: TextStyle(color: palette.textMuted, fontSize: 14)),
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
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: NxIconButton(icon: Icons.person_add_alt_rounded, tooltip: 'Add a new supplier', onTap: _showAddSupplierDialog),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Product ----
          DropdownButtonFormField<String>(
            initialValue: _selectedProductId,
            isExpanded: true,
            decoration: _dd(label: 'Product *'),
            hint: Text(
              _selectedShopId == null
                  ? 'Pick a shop first'
                  : _productsForShop.isEmpty
                      ? 'No products in this shop yet'
                      : 'Select product to restock',
              style: TextStyle(color: palette.textMuted, fontSize: 14),
            ),
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
                Icon(Icons.inventory_2_outlined, size: 14, color: palette.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Current stock: $currentStock'
                  '${_formQuantity > 0 ? '  →  after restock: ${currentStock + _formQuantity}' : ''}',
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // ---- Quantity + unit cost ----
          Row(
            children: [
              Expanded(
                child: NxTextField(
                  controller: _quantityController,
                  label: 'Quantity *',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NxTextField(
                  controller: _costController,
                  label: 'Unit cost *',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: NxButton(
              label: 'Add product to purchase',
              icon: Icons.add_rounded,
              variant: NxButtonVariant.soft,
              onPressed: _addItem,
            ),
          ),

          // ---- Items list ----
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 10),
            Text('PURCHASE ITEMS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: palette.textMuted)),
            const SizedBox(height: 8),
            ..._items.map(_buildItemRow),
            const SizedBox(height: 6),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: palette.textPrimary)),
                Text(
                  _money(_orderTotal),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: palette.success),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // ---- Optional details ----
          InkWell(
            onTap: _pickDeliveryDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.border)),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 18, color: palette.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _expectedDelivery != null ? 'Expected delivery · ${_formatDate(_expectedDelivery!)}' : 'Expected delivery (optional)',
                      style: TextStyle(fontSize: 14, color: _expectedDelivery != null ? palette.textPrimary : palette.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          NxTextField(controller: _notesController, label: 'Notes (optional)', maxLines: 2),
          NxSwitchRow(
            title: 'Receive stock now',
            subtitle: 'Adds the items to inventory immediately',
            value: _receiveNow,
            onToggle: (value) => setState(() => _receiveNow = value),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: NxButton(
              label: _receiveNow ? 'Buy & add to stock' : 'Create purchase order',
              icon: Icons.check_circle_outline_rounded,
              expanded: true,
              onPressed: _creating ? null : _createPurchase,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dd({required String label}) {
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

  Widget _buildItemRow(_RestockItem item) {
    final palette = nxOf(context);
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: palette.textPrimary),
                ),
                Text(
                  '${item.quantity} × ${_money(item.unitCost)}',
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                ),
              ],
            ),
          ),
          Text(_money(item.subtotal), style: TextStyle(fontWeight: FontWeight.w700, color: palette.textPrimary)),
          const SizedBox(width: 4),
          NxIconButton(icon: Icons.close_rounded, tooltip: 'Remove', onTap: () => setState(() => _items.remove(item))),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // RIGHT: purchase orders
  // ----------------------------------------------------------

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return const NxEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No purchase orders yet',
        message: 'Create your first restock to bring stock into inventory.',
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
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
    final palette = nxOf(context);
    final canApprove = order.status == 'DRAFT';
    final canReceive = order.status == 'APPROVED' ||
        order.status == 'ORDERED' ||
        order.status == 'PARTIALLY_RECEIVED';
    final canCancel = order.status != 'RECEIVED' && order.status != 'CANCELLED';

    return NxCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          iconColor: palette.textMuted,
          collapsedIconColor: palette.textMuted,
          title: Text(
            order.supplierName.isEmpty ? 'Purchase order' : order.supplierName,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: palette.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_shopName(order.shopId).isEmpty ? '' : _shopName(order.shopId)}'
              ' · ${order.lines.length} product${order.lines.length == 1 ? '' : 's'}'
              ' · ${_formatDate(order.createdAt)}',
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              NxBadge(text: _statusLabel(order.status), variant: nxStatusVariant(order.status)),
              const SizedBox(height: 4),
              Text(_money(order.total), style: TextStyle(fontWeight: FontWeight.w700, color: palette.textPrimary)),
            ],
          ),
          children: [
            for (final line in order.lines) _buildLineRow(line),
            if (order.lines.isNotEmpty &&
                (order.status == 'PARTIALLY_RECEIVED' || order.status == 'RECEIVED')) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: order.totalOrdered == 0 ? 0 : order.totalReceived / order.totalOrdered,
                backgroundColor: palette.surfaceAlt,
                color: palette.success,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
            if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notes: ${order.notes}',
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                ),
              ),
            ],
            if (canApprove || canReceive || canCancel) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canApprove)
                    NxButton(label: 'Approve', variant: NxButtonVariant.soft, icon: Icons.thumb_up_outlined, onPressed: () => _approveOrder(order)),
                  if (canApprove && canReceive) const SizedBox(width: 8),
                  if (canReceive)
                    NxButton(
                      label: order.status == 'PARTIALLY_RECEIVED' ? 'Receive remaining' : 'Receive all',
                      icon: Icons.move_to_inbox_outlined,
                      onPressed: () => _receiveOrder(order),
                    ),
                  if (canReceive && canCancel) const SizedBox(width: 8),
                  if (canCancel)
                    NxButton(label: 'Cancel order', variant: NxButtonVariant.dangerSoft, onPressed: () => _cancelOrder(order)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PARTIALLY_RECEIVED':
        return 'Partial';
      default:
        // Title-case single-word statuses; multi-word stays as-is.
        final lower = status.toLowerCase();
        return lower[0].toUpperCase() + lower.substring(1);
    }
  }

  Widget _buildLineRow(PurchaseOrderLine line) {
    final palette = nxOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName.isEmpty ? 'Product' : line.productName,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.textPrimary),
                ),
                Text(
                  'Ordered ${line.orderedQuantity} · Received ${line.receivedQuantity} · ${_money(line.purchasePrice)}/unit',
                  style: TextStyle(fontSize: 11, color: palette.textMuted),
                ),
              ],
            ),
          ),
          Text(_money(line.subtotal), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
        ],
      ),
    );
  }
}
