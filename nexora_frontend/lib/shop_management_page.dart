import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/shop.dart';

class ShopManagementPage extends StatefulWidget {
  const ShopManagementPage({super.key});

  @override
  State<ShopManagementPage> createState() => _ShopManagementPageState();
}

class _ShopManagementPageState extends State<ShopManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ---------------- Shops ----------------
  List<Shop> shops = [];
  bool isLoading = true;
  String error = '';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _logoUrlController = TextEditingController();
  bool _isActive = true;
  String? _editingShopId;

  // ---------------- Suppliers ----------------
  List<Map<String, dynamic>> suppliers = [];
  bool suppliersLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShops();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  // =======================================================================
  // SHOPS
  // =======================================================================
  Future<void> _loadShops() async {
    try {
      final data = await ApiService.getShops();
      if (!mounted) return;
      setState(() {
        shops = data;
        isLoading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  void _showShopDialog({Shop? shop}) {
    _editingShopId = shop?.id;
    if (shop != null) {
      _nameController.text = shop.name;
      _taxIdController.text = shop.taxId ?? '';
      _phoneController.text = shop.phone ?? '';
      _addressController.text = shop.address ?? '';
      _logoUrlController.text = shop.logoUrl ?? '';
      _isActive = shop.isActive;
    } else {
      _nameController.clear();
      _taxIdController.clear();
      _phoneController.clear();
      _addressController.clear();
      _logoUrlController.clear();
      _isActive = true;
    }
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_editingShopId == null ? 'Add Shop' : 'Edit Shop'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Shop Name'),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Shop name is required' : null,
                  ),
                  TextFormField(
                    controller: _taxIdController,
                    decoration: const InputDecoration(labelText: 'Tax ID'),
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  TextFormField(
                    controller: _logoUrlController,
                    decoration: const InputDecoration(labelText: 'Logo URL'),
                  ),
                  CheckboxListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (v) => setDialogState(() => _isActive = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveShop(),
              child: Text(_editingShopId == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveShop() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final data = {
      'name': _nameController.text.trim(),
      'tax_id': _taxIdController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'logo_url': _logoUrlController.text.trim(),
      'is_active': _isActive,
    };
    try {
      if (_editingShopId == null) {
        await ApiService.createShop(data);
      } else {
        await ApiService.updateShop(_editingShopId!, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      _loadShops();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _editingShopId == null ? 'Shop added successfully' : 'Shop updated'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save shop: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _deleteShop(Shop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: Text('Are you sure you want to delete "${shop.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteShop(shop.id);
      _loadShops();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop deleted'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete shop: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildShopsTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error.isNotEmpty) {
      return Center(child: Text('Error: $error'));
    }
    if (shops.isEmpty) {
      return const Center(child: Text('No shops yet. Add your first shop!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: shops.length,
      itemBuilder: (_, i) {
        final shop = shops[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.storefront, color: Colors.deepPurple),
            ),
            title: Text(shop.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((shop.address ?? '').isNotEmpty) Text(shop.address ?? ''),
                if ((shop.phone ?? '').isNotEmpty) Text('📞 ${shop.phone}'),
                if ((shop.taxId ?? '').isNotEmpty) Text('🧾 Tax ID: ${shop.taxId}'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showShopDialog(shop: shop),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteShop(shop),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =======================================================================
  // SUPPLIERS
  // =======================================================================
  Future<void> _loadSuppliers() async {
    try {
      final data = await ApiService.getSuppliers();
      if (!mounted) return;
      setState(() {
        suppliers = data;
        suppliersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => suppliersLoading = false);
    }
  }

  void _showSupplierDialog({Map<String, dynamic>? supplier}) {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: supplier?['name']?.toString() ?? '');
    final contactController =
        TextEditingController(text: supplier?['contact_person']?.toString() ?? '');
    final phoneController =
        TextEditingController(text: supplier?['phone']?.toString() ?? '');
    final emailController =
        TextEditingController(text: supplier?['email']?.toString() ?? '');
    final editingId = supplier?['id']?.toString();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(editingId == null ? 'Add Supplier' : 'Edit Supplier'),
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
                  decoration:
                      const InputDecoration(labelText: 'Supplier name *'),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Supplier name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactController,
                  decoration:
                      const InputDecoration(labelText: 'Contact person'),
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
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final data = {
                'name': nameController.text.trim(),
                'contact_person': contactController.text.trim(),
                'phone': phoneController.text.trim(),
                'email': emailController.text.trim(),
              };
              try {
                if (editingId == null) {
                  await ApiService.createSupplier(data);
                } else {
                  await ApiService.updateSupplier(editingId, data);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                await _loadSuppliers();
                _showSnack(editingId == null
                    ? 'Supplier added'
                    : 'Supplier updated');
              } catch (e) {
                _showSnack('Failed to save supplier: $e', isError: true);
              }
            },
            child: Text(editingId == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(Map<String, dynamic> supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text(
            'Delete "${supplier['name'] ?? 'this supplier'}"? Their purchase orders will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteSupplier(supplier['id'].toString());
      await _loadSuppliers();
      _showSnack('Supplier deleted');
    } catch (e) {
      _showSnack('Failed to delete supplier: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildSuppliersTab() {
    if (suppliersLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (suppliers.isEmpty) {
      return const Center(
        child: Text('No suppliers yet.\nAdd one, then restock in Buy Information.',
            textAlign: TextAlign.center),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: suppliers.length,
      itemBuilder: (_, i) {
        final s = suppliers[i];
        final contact = s['contact_person']?.toString() ?? '';
        final phone = s['phone']?.toString() ?? '';
        final email = s['email']?.toString() ?? '';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.local_shipping_outlined, color: Colors.teal),
            ),
            title: Text(s['name']?.toString() ?? 'Supplier',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contact.isNotEmpty) Text('👤 $contact'),
                if (phone.isNotEmpty) Text('📞 $phone'),
                if (email.isNotEmpty) Text('✉️ $email'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit supplier',
                  onPressed: () => _showSupplierDialog(supplier: s),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete supplier',
                  onPressed: () => _deleteSupplier(s),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =======================================================================
  // SCAFFOLD
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Shops', icon: Icon(Icons.storefront)),
            Tab(text: 'Suppliers', icon: Icon(Icons.local_shipping_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShopsTab(),
          _buildSuppliersTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) => FloatingActionButton(
          tooltip: _tabController.index == 0 ? 'Add shop' : 'Add supplier',
          onPressed: () {
            if (_tabController.index == 0) {
              _showShopDialog();
            } else {
              _showSupplierDialog();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
