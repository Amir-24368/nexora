import 'package:flutter/material.dart';
import 'models/customer.dart';
import 'models/sale.dart';
import 'services/api_service.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  List<Sale> sales = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      final data = await ApiService.getSales(customerId: widget.customer.id);
      setState(() {
        sales = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalOrders = sales.length;
    final avgOrder = totalOrders > 0 ? widget.customer.totalSpent / totalOrders : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer.fullName} Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.customer.fullName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.customer.email ?? 'No email',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          'Phone: ${widget.customer.phone}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Spent', '\$${widget.customer.totalSpent.toStringAsFixed(2)}', Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Total Orders', totalOrders.toString(), Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Average Order', '\$${avgOrder.toStringAsFixed(2)}', Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Member Since', widget.customer.createdAt.toLocal().toString().split(' ')[0], Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Order History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  sales.isEmpty
                      ? const Center(child: Text('No orders yet'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sales.length,
                          itemBuilder: (_, i) {
                            final sale = sales[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.shopping_bag),
                                title: Text('Order #${sale.id}'),
                                subtitle: Text('Total: \$${sale.totalAmount} | Date: ${sale.saleDate.toLocal().toString().split(' ')[0]}'),
                                trailing: Text(sale.status),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}