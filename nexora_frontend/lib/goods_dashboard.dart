import 'package:flutter/material.dart';
import 'goods_management_page.dart';
import 'goods_info_management_page.dart';
import 'logout_helper.dart';

class GoodsDashboard extends StatelessWidget {
  const GoodsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goods Section'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // close the dialog first
                        performLogout(context);            // then logout with the page's own context
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionCard(
                context,
                title: 'Goods Management',
                subtitle: 'Add, edit, delete products',
                icon: Icons.inventory,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoodsManagementPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              _buildOptionCard(
                context,
                title: 'Goods Information Management',
                subtitle: 'Track buying & selling volumes',
                icon: Icons.analytics,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoodsInfoManagementPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}