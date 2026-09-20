import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/shop.dart';

class ShopManagementPage extends StatefulWidget {
  const ShopManagementPage({super.key});

  @override
  State<ShopManagementPage> createState() => _ShopManagementPageState();
}

class _ShopManagementPageState extends State<ShopManagementPage> {
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

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final data = await ApiService.getShops();
      setState(() {
        shops = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
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
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(_editingShopId == null ? 'Add Shop' : 'Edit Shop'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Shop Name *'),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
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
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: _logoUrlController,
                    decoration: const InputDecoration(labelText: 'Logo URL'),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (val) => setDialogState(() => _isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: _saveShop,
                child: Text(_editingShopId == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final data = {
        'name': _nameController.text.trim(),
        'tax_id': _taxIdController.text.trim().isEmpty ? null : _taxIdController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'logo_url': _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
        'is_active': _isActive,
      };

      if (_editingShopId == null) {
        await ApiService.createShop(data);
      } else {
        await ApiService.updateShop(_editingShopId!, data);
      }
      Navigator.pop(context);
      _loadShops();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingShopId == null ? 'Shop added' : 'Shop updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteShop(String id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Shop'),
        content: const Text('Are you sure? This will affect all products in this shop.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.deleteShop(id);
                Navigator.pop(context);
                _loadShops();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
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
        title: const Text('Shop Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showShopDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text('Error: $error'))
              : shops.isEmpty
                  ? const Center(child: Text('No shops yet. Tap + to add.'))
                  : ListView.builder(
                      itemCount: shops.length,
                      itemBuilder: (_, i) {
                        final s = shops[i];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: s.logoUrl != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(s.logoUrl!),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.store),
                                  ),
                            title: Text(s.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (s.phone != null) Text('Phone: ${s.phone}'),
                                if (s.address != null) Text('Address: ${s.address}'),
                                Text(s.isActive ? 'Active' : 'Inactive'),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showShopDialog(shop: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteShop(s.id),
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