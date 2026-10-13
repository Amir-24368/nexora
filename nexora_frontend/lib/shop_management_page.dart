import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/shop.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

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

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    nxSnack(context, message, isError: isError);
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
      builder: (dialogContext) => nxDialog(
        context: dialogContext,
        title: _editingShopId == null ? 'Add shop' : 'Edit shop',
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NxTextField(
                  controller: _nameController,
                  label: 'Shop name',
                  autofocus: true,
                  validator: (v) => v!.trim().isEmpty ? 'Shop name is required' : null,
                ),
                const SizedBox(height: 10),
                NxTextField(controller: _taxIdController, label: 'Tax ID'),
                const SizedBox(height: 10),
                NxTextField(controller: _phoneController, label: 'Phone'),
                const SizedBox(height: 10),
                NxTextField(controller: _addressController, label: 'Address'),
                const SizedBox(height: 10),
                NxTextField(controller: _logoUrlController, label: 'Logo URL'),
                const SizedBox(height: 4),
                NxSwitchRow(
                  title: 'Active',
                  subtitle: 'Products from this shop appear for sale',
                  value: _isActive,
                  onToggle: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          NxButton(label: 'Cancel', variant: NxButtonVariant.ghost, onPressed: () => Navigator.pop(dialogContext)),
          NxButton(label: _editingShopId == null ? 'Add shop' : 'Save', onPressed: _saveShop),
        ],
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
      _showSnack(_editingShopId == null ? 'Shop added' : 'Shop updated');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save shop: $e', isError: true);
    }
  }

  Future<void> _deleteShop(Shop shop) async {
    final confirmed = await nxConfirm(
      context,
      title: 'Delete shop',
      message: 'Delete "${shop.name}"? Products assigned to this shop may be affected.',
      confirmLabel: 'Delete',
      variant: NxButtonVariant.danger,
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteShop(shop.id);
      _loadShops();
      if (!mounted) return;
      _showSnack('Shop deleted');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to delete shop: $e', isError: true);
    }
  }

  Widget _buildShopsTab() {
    final palette = nxOf(context);
    if (isLoading) {
      return const NxLoader();
    }
    if (error.isNotEmpty) {
      return NxErrorView(message: error, onRetry: _loadShops);
    }
    if (shops.isEmpty) {
      return NxEmptyState(
        icon: Icons.storefront_outlined,
        title: 'No shops yet',
        message: 'Add your first shop — products and purchases all live inside shops.',
        actionLabel: 'Add shop',
        onAction: () => _showShopDialog(),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
      itemCount: shops.length,
      itemBuilder: (_, i) {
        final shop = shops[i];
        return NxCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              NxIconBlock(icon: Icons.storefront_outlined, color: palette.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(shop.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                        ),
                        NxBadge(text: shop.isActive ? 'Active' : 'Inactive', variant: shop.isActive ? NxBadgeVariant.success : NxBadgeVariant.neutral),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        if ((shop.address ?? '').isNotEmpty)
                          _meta(Icons.place_outlined, shop.address!, palette),
                        if ((shop.phone ?? '').isNotEmpty)
                          _meta(Icons.phone_outlined, shop.phone!, palette),
                        if ((shop.taxId ?? '').isNotEmpty)
                          _meta(Icons.receipt_outlined, 'Tax ID ${shop.taxId}', palette),
                      ],
                    ),
                  ],
                ),
              ),
              NxIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', onTap: () => _showShopDialog(shop: shop)),
              NxIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete', color: palette.danger, onTap: () => _deleteShop(shop)),
            ],
          ),
        );
      },
    );
  }

  Widget _meta(IconData icon, String text, NxTheme palette) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: palette.textMuted),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: palette.textMuted)),
      ],
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
      builder: (dialogContext) => nxDialog(
        context: dialogContext,
        title: editingId == null ? 'Add supplier' : 'Edit supplier',
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NxTextField(
                controller: nameController,
                label: 'Supplier name',
                autofocus: true,
                validator: (v) => v!.trim().isEmpty ? 'Supplier name is required' : null,
              ),
              const SizedBox(height: 10),
              NxTextField(controller: contactController, label: 'Contact person'),
              const SizedBox(height: 10),
              NxTextField(controller: phoneController, label: 'Phone'),
              const SizedBox(height: 10),
              NxTextField(controller: emailController, label: 'Email', keyboardType: TextInputType.emailAddress),
            ],
          ),
        ),
        actions: [
          NxButton(label: 'Cancel', variant: NxButtonVariant.ghost, onPressed: () => Navigator.pop(dialogContext)),
          NxButton(label: editingId == null ? 'Add supplier' : 'Save', onPressed: () async {
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
              _showSnack(editingId == null ? 'Supplier added' : 'Supplier updated');
            } catch (e) {
              _showSnack('Failed to save supplier: $e', isError: true);
            }
          }),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(Map<String, dynamic> supplier) async {
    final confirmed = await nxConfirm(
      context,
      title: 'Delete supplier',
      message: 'Delete "${supplier['name'] ?? 'this supplier'}"? Their purchase orders will also be removed.',
      confirmLabel: 'Delete',
      variant: NxButtonVariant.danger,
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

  Widget _buildSuppliersTab() {
    final palette = nxOf(context);
    if (suppliersLoading) {
      return const NxLoader();
    }
    if (suppliers.isEmpty) {
      return NxEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No suppliers yet',
        message: 'Add one, then restock in Buy Information.',
        actionLabel: 'Add supplier',
        onAction: () => _showSupplierDialog(),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
      itemCount: suppliers.length,
      itemBuilder: (_, i) {
        final s = suppliers[i];
        final contact = s['contact_person']?.toString() ?? '';
        final phone = s['phone']?.toString() ?? '';
        final email = s['email']?.toString() ?? '';
        return NxCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              NxIconBlock(icon: Icons.local_shipping_outlined, color: palette.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name']?.toString() ?? 'Supplier', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        if (contact.isNotEmpty) _meta(Icons.person_outline_rounded, contact, palette),
                        if (phone.isNotEmpty) _meta(Icons.phone_outlined, phone, palette),
                        if (email.isNotEmpty) _meta(Icons.mail_outline_rounded, email, palette),
                      ],
                    ),
                  ],
                ),
              ),
              NxIconButton(icon: Icons.edit_outlined, tooltip: 'Edit supplier', onTap: () => _showSupplierDialog(supplier: s)),
              NxIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete supplier', color: palette.danger, onTap: () => _deleteSupplier(s)),
            ],
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
    final palette = nxOf(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: const NxBackButton(),
          title: const Text('Shops & Suppliers'),
          bottom: TabBar(
            dividerColor: palette.border,
            labelColor: palette.primary,
            unselectedLabelColor: palette.textMuted,
            indicatorColor: palette.primary,
            tabs: const [
              Tab(text: 'Shops', icon: Icon(Icons.storefront_outlined, size: 20)),
              Tab(text: 'Suppliers', icon: Icon(Icons.local_shipping_outlined, size: 20)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 0) {
              _showShopDialog();
            } else {
              _showSupplierDialog();
            }
          },
          backgroundColor: palette.primary,
          foregroundColor: palette.textOnAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded),
          label: AnimatedBuilder(
            animation: _tabController,
            builder: (_, __) => Text(_tabController.index == 0 ? 'New shop' : 'New supplier'),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildShopsTab(),
            _buildSuppliersTab(),
          ],
        ),
      ),
    );
  }
}
