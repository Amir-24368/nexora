import 'package:flutter/material.dart';
import 'logout_helper.dart';
import 'user_shopping_page.dart';
import 'user_cart_page.dart';
import 'user_orders_page.dart';
import 'user_profile_page.dart';

class UserDashboard extends StatefulWidget {
  final String username;
  const UserDashboard({super.key, required this.username});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const UserShoppingPage(),
      UserCartPage(username: widget.username),
      const UserOrdersPage(),
      UserProfilePage(username: widget.username),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => performLogout(context),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}