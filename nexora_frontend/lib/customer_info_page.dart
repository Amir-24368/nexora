import 'dart:convert';

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/customer.dart';
import 'models/sale.dart';
import 'customer_detail_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class CustomerInfoPage extends StatefulWidget {
  const CustomerInfoPage({super.key});

  @override
  State<CustomerInfoPage> createState() => _CustomerInfoPageState();
}

class _CustomerInfoPageState extends State<CustomerInfoPage> {
  List<Customer> allCustomers = [];
  List<Customer> filteredCustomers = [];
  Map<String, List<Sale>> salesByCustomer = {};
  double totalSpentAll = 0;
  final Set<String> _expandedIds = {}; // which customer rows are expanded
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final customers = await ApiService.getCustomers();
      final sales = await ApiService.getSales();
      // Group every order under its customer so the list can show merged
      // per-customer stats: order count, dollars spent, since-date.
      final map = <String, List<Sale>>{};
      var spent = 0.0;
      for (final s in sales) {
        // Money math counts completed orders only -- matching the RFM engine,
        // so a cancelled/returned order never inflates the totals.
        if (s.status == 'COMPLETED') spent += s.totalAmount;
        final id = s.customer?.id ?? '';
        if (id.isNotEmpty) map.putIfAbsent(id, () => []).add(s);
      }
      setState(() {
        allCustomers = customers;
        filteredCustomers = List.from(allCustomers);
        salesByCustomer = map;
        totalSpentAll = spent;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _filterCustomers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredCustomers = allCustomers
          .where((c) => c.fullName.toLowerCase().contains(query) || (c.email?.toLowerCase().contains(query) ?? false))
          .toList();
    });
  }

  // ============ CRUD ============

  /// DRF errors arrive as text like {"email": ["...message..."]} -- turn
  /// them into human-readable lines instead of dumping raw JSON.
  String _readableError(Object e) {
    var msg = e.toString();
    if (msg.startsWith('Exception: ')) msg = msg.substring(11);
    try {
      final decoded = jsonDecode(msg);
      if (decoded is Map) {
        return decoded.entries
            .map((en) => en.value is List ? '${en.key}: ${(en.value as List).join(', ')}' : '${en.key}: ${en.value}')
            .join('\n');
      }
      if (decoded is List) return decoded.join(', ');
    } catch (_) {
      // Not JSON -- use the raw message.
    }
    return msg;
  }

  Future<void> _openCustomerDialog({Customer? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => nxDialog(
        context: dialogCtx,
        title: existing == null ? 'Add customer' : 'Edit customer',
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NxTextField(controller: nameCtrl, label: 'Full name *', validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                const SizedBox(height: 12),
                NxTextField(controller: phoneCtrl, label: 'Phone number', keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                NxTextField(
                  controller: emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isNotEmpty && !t.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                NxTextField(controller: addressCtrl, label: 'Address'),
              ],
            ),
          ),
        ),
        actions: [
          NxButton(label: 'Cancel', variant: NxButtonVariant.ghost, onPressed: () => Navigator.pop(dialogCtx, false)),
          NxButton(
            label: existing == null ? 'Add' : 'Save',
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogCtx, true);
              }
            },
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;

    final data = {
      'full_name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
    };
    try {
      if (existing == null) {
        await ApiService.createCustomer(data);
      } else {
        await ApiService.updateCustomer(existing.id, data);
      }
      if (!mounted) return;
      await _loadData();
      nxSnack(context, existing == null ? 'Customer added' : 'Customer updated');
    } catch (e) {
      if (!mounted) return;
      nxSnack(context, _readableError(e), isError: true);
    }
  }

  Future<void> _deleteCustomer(Customer c) async {
    final confirmed = await nxConfirm(
      context,
      title: 'Delete ${c.fullName}?',
      message: 'This removes the customer record. Their past orders stay in the system.',
      confirmLabel: 'Delete',
      variant: NxButtonVariant.danger,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteCustomer(c.id);
      _expandedIds.remove(c.id);
      if (!mounted) return;
      await _loadData();
      nxSnack(context, 'Customer deleted');
    } catch (e) {
      if (!mounted) return;
      nxSnack(context, _readableError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_rounded),
            tooltip: 'Add customer',
            onPressed: () => _openCustomerDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const NxLoader(label: 'Loading customers...')
          : error.isNotEmpty
              ? NxErrorView(message: error, onRetry: _loadData)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Customers',
                              value: allCustomers.length.toString(),
                              icon: Icons.people_alt_rounded,
                              color: palette.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Total spent',
                              value: '\$${totalSpentAll.toStringAsFixed(2)}',
                              icon: Icons.payments_rounded,
                              color: palette.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: NxTextField(
                        controller: searchController,
                        hint: 'Search by name or email...',
                        prefixIcon: Icons.search_rounded,
                      ),
                    ),
                    Expanded(
                      child: filteredCustomers.isEmpty
                          ? NxEmptyState(
                              icon: Icons.people_outline_rounded,
                              title: 'No customers found',
                              message: 'Add your first customer to start tracking orders.',
                              actionLabel: 'Add customer',
                              onAction: () => _openCustomerDialog(),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: filteredCustomers.length,
                              itemBuilder: (_, i) {
                                final c = filteredCustomers[i];
                                final orders = salesByCustomer[c.id] ?? const <Sale>[];
                                DateTime? first;
                                for (final s in orders) {
                                  if (first == null || s.saleDate.isBefore(first)) first = s.saleDate;
                                }
                                // Compute from the customer's real orders, not the stored
                                // snapshot -- stale totals can't contradict the list anymore.
                                final spent = orders.where((s) => s.status == 'COMPLETED').fold<double>(0, (sum, s) => sum + s.totalAmount);
                                final isExpanded = _expandedIds.contains(c.id);
                                return _CustomerCard(
                                  customer: c,
                                  orders: orders,
                                  firstOrder: first,
                                  spent: spent,
                                  expanded: isExpanded,
                                  onToggle: () => setState(() {
                                    isExpanded ? _expandedIds.remove(c.id) : _expandedIds.add(c.id);
                                  }),
                                  onEdit: () => _openCustomerDialog(existing: c),
                                  onDelete: () => _deleteCustomer(c),
                                  onOpenProfile: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CustomerDetailPage(customer: c)),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return NxCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          NxIconBlock(icon: icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.textMuted)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: palette.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.orders,
    required this.firstOrder,
    required this.spent,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenProfile,
  });

  final Customer customer;
  final List<Sale> orders;
  final DateTime? firstOrder;
  final double spent;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    final initials = customer.fullName.trim().isNotEmpty
        ? customer.fullName.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join()
        : '?';
    return NxCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onToggle,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: nxHeroGradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Phone: ${customer.phone.isNotEmpty ? customer.phone : '-'} | Email: ${customer.email ?? 'N/A'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: palette.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      firstOrder != null ? '${orders.length} order(s) · since ${_date(firstOrder!)}' : 'No purchases yet',
                      style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${spent.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: palette.success)),
                  Text('spent', style: TextStyle(fontSize: 11, color: palette.textMuted)),
                ],
              ),
              Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20, color: palette.textMuted),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ORDER HISTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: palette.textMuted)),
            ),
            const SizedBox(height: 4),
            if (orders.isEmpty)
              Text('No purchases yet', style: TextStyle(fontSize: 12, color: palette.textMuted))
            else
              ...orders.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order #${s.id} · ${_date(s.saleDate)} · ${s.items.length} item(s)',
                            style: TextStyle(fontSize: 12, color: palette.textMuted),
                          ),
                        ),
                        Text(
                          '\$${s.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textPrimary),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NxButton(label: 'Edit', variant: NxButtonVariant.ghost, icon: Icons.edit_outlined, height: 38, onPressed: onEdit),
                const SizedBox(width: 8),
                NxButton(label: 'Delete', variant: NxButtonVariant.dangerSoft, icon: Icons.delete_outline_rounded, height: 38, onPressed: onDelete),
                const SizedBox(width: 8),
                NxButton(label: 'Full profile', variant: NxButtonVariant.soft, icon: Icons.open_in_new_rounded, height: 38, onPressed: onOpenProfile),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _date(DateTime d) => d.toLocal().toString().split(' ')[0];
}
