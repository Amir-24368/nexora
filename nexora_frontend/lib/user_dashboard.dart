import 'package:flutter/material.dart';
import 'user_shopping_page.dart';
import 'user_cart_page.dart';
import 'user_orders_page.dart';
import 'user_profile_page.dart';
import 'ui/theme.dart';

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
    final palette = nxOf(context);
    final pages = [
      const UserShoppingPage(),
      UserCartPage(username: widget.username),
      const UserOrdersPage(),
      UserProfilePage(username: widget.username),
    ];
    const destinations = [
      (icon: Icons.storefront_rounded, activeIcon: Icons.storefront, label: 'Shop'),
      (icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Cart'),
      (icon: Icons.receipt_outlined, activeIcon: Icons.receipt_rounded, label: 'Orders'),
      (icon: Icons.person_outline_rounded, activeIcon: Icons.person, label: 'Profile'),
    ];

    return Scaffold(
      backgroundColor: palette.background,
      body: pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: palette.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: palette.primarySoft,
          height: 68,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon, size: 24),
                selectedIcon: Icon(d.activeIcon, size: 24, color: palette.primary),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}
