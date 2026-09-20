import 'dart:convert';

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/customer.dart';
import 'models/sale.dart';
import 'customer_detail_page.dart';

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
      filteredCustomers = allCustomers.where((c) =>
        c.fullName.toLowerCase().contains(query) ||
        (c.email?.toLowerCase().contains(query) ?? false)
      ).toList();
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
            .map((en) => en.value is List
                ? '${en.key}: ${(en.value as List).join(', ')}'
                : '${en.key}: ${en.value}')
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
      builder: (dialogCtx) => AlertDialog(
        title: Text(existing == null ? 'Add Customer' : 'Edit Customer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isNotEmpty && !t.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogCtx, true);
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Customer added' : 'Customer updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readableError(e)), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCustomer(Customer c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete ${c.fullName}?'),
        content: const Text(
            'This removes the customer record. Their past orders stay in the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteCustomer(c.id);
      _expandedIds.remove(c.id);
      if (!mounted) return;
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readableError(e)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Add Customer',
            onPressed: () => _openCustomerDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                      'Total Customers', allCustomers.length.toString(), Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                      'Total Spent', '${totalSpentAll.toStringAsFixed(2)} USD', Colors.green),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(child: Text('No customers found'))
                : ListView.builder(
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
                      final spent = orders
                          .where((s) => s.status == 'COMPLETED')
                          .fold<double>(0, (sum, s) => sum + s.totalAmount);
                      final isExpanded = _expandedIds.contains(c.id);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(c.fullName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone: ${c.phone.isNotEmpty ? c.phone : '-'} | Email: ${c.email ?? 'N/A'}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    first != null
                                        ? '${orders.length} order(s) · Since ${first.toLocal().toString().split(' ')[0]}'
                                        : 'No purchases yet',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                          trailing: Text('Spent: \$${spent.toStringAsFixed(2)}'),
                              onTap: () => setState(() {
                                isExpanded
                                    ? _expandedIds.remove(c.id)
                                    : _expandedIds.add(c.id);
                              }),
                        ),
                              if (isExpanded)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const Text('Order history',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      if (orders.isEmpty)
                                        const Text('No purchases yet',
                                            style: TextStyle(fontSize: 12)),
                                      ...orders.map(
                                        (s) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Order #${s.id} · ${s.saleDate.toLocal().toString().split(' ')[0]} · ${s.items.length} item(s)',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                              Text(
                                                '${s.totalAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _openCustomerDialog(existing: c),
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Edit'),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _deleteCustomer(c),
                                            icon: const Icon(Icons.delete_outline, size: 16),
                                            label: const Text('Delete'),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          ),
                                          TextButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CustomerDetailPage(customer: c),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.open_in_new, size: 16),
                                            label: const Text('Full profile'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}