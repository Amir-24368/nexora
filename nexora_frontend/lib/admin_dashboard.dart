import 'package:flutter/material.dart';
import 'goods_dashboard.dart';
import 'customer_info_page.dart';
import 'buy_info_page.dart';
import 'sale_info_page.dart';
import 'categories_page.dart';
import 'shop_management_page.dart';
import 'logout_helper.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.dashboard, color: Colors.blue.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Manage your business operations',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Logout button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (shouldLogout == true) {
                          await performLogout(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Dashboard cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width < 800 ? 1 : 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildDashboardCard(
                      context,
                      title: 'Goods Information',
                      subtitle: 'Manage products, stock, prices',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoodsDashboard(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Customer Info',
                      subtitle: 'View and manage customers',
                      icon: Icons.people_outline,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerInfoPage()),
                      ),
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Buy Information',
                      subtitle: 'Purchase orders & suppliers',
                      icon: Icons.shopping_cart_outlined,
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BuyInfoPage()),
                      ),
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Sale Information',
                      subtitle: 'Sales reports & transactions',
                      icon: Icons.attach_money_outlined,
                      color: Colors.redAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SaleInfoPage()),
                      ),
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Category Management',
                      subtitle: 'Add, edit, delete categories',
                      icon: Icons.category,
                      color: Colors.indigo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CategoriesPage()),
                      ),
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'Shop Management',
                      subtitle: 'Manage shops & tenants',
                      icon: Icons.storefront,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShopManagementPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}