import 'package:flutter/material.dart';
import 'goods_dashboard.dart';
import 'customer_info_page.dart';
import 'buy_info_page.dart';
import 'sale_info_page.dart';
import 'categories_page.dart';
import 'shop_management_page.dart';
import 'logout_helper.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nxOf(context).background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final tiles = [
              _Tile(title: 'Goods', subtitle: 'Products, stock & pricing', icon: Icons.inventory_2_outlined, color: const Color(0xFF0EAF7B), builder: (_) => const GoodsDashboard()),
              _Tile(title: 'Customers', subtitle: 'CRM & purchase history', icon: Icons.people_outline_rounded, color: const Color(0xFFE8A13B), builder: (_) => const CustomerInfoPage()),
              _Tile(title: 'Purchasing', subtitle: 'Purchase orders & suppliers', icon: Icons.local_shipping_outlined, color: const Color(0xFF7C3AED), builder: (_) => const BuyInfoPage()),
              _Tile(title: 'Sales', subtitle: 'Sales reports & transactions', icon: Icons.ssid_chart_rounded, color: const Color(0xFFE5484D), builder: (_) => const SaleInfoPage()),
              _Tile(title: 'Categories', subtitle: 'Organize your catalog', icon: Icons.category_rounded, color: const Color(0xFF3B9DDB), builder: (_) => const CategoriesPage()),
              _Tile(title: 'Shops', subtitle: 'Stores, branches & tenants', icon: Icons.storefront_outlined, color: const Color(0xFF4F46E5), builder: (_) => const ShopManagementPage()),
            ];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AdminHero(onLogout: () => _confirmLogout(context)),
                  const SizedBox(height: 24),
                  Text(
                    'WORKSPACE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: nxOf(context).textMuted),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: wide ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: wide ? 1.35 : 1.15,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [for (final t in tiles) _TileCard(tile: t)],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await nxConfirm(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out of Nexora?',
      confirmLabel: 'Log out',
      variant: NxButtonVariant.danger,
    );
    if (ok && context.mounted) {
      await performLogout(context);
    }
  }
}

/// One dashboard destination.
class _Tile {
  const _Tile({required this.title, required this.subtitle, required this.icon, required this.color, required this.builder});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}

class _TileCard extends StatelessWidget {
  const _TileCard({required this.tile});
  final _Tile tile;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return NxCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: tile.builder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NxIconBlock(icon: tile.icon, color: tile.color),
          const Spacer(),
          Text(tile.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: palette.textPrimary)),
          const SizedBox(height: 3),
          Text(tile.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.3, color: palette.textMuted)),
        ],
      ),
    );
  }
}

/// Gradient welcome header with brand + theme toggle + logout.
class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final onAccent = NxTheme.light.textOnAccent;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: nxHeroGradient),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x334F46E5), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Nexora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: onAccent)),
              const Spacer(),
              _HeroAction(icon: Icons.dark_mode_outlined, label: 'Theme', onTap: () {
                final mq = MediaQuery.of(context);
                final dark = mq.platformBrightness == Brightness.dark;
                nxThemeMode.value = dark ? ThemeMode.light : ThemeMode.dark;
              }),
              const SizedBox(width: 8),
              _HeroAction(icon: Icons.logout_rounded, label: 'Log out', onTap: onLogout),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Good to see you.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: onAccent),
          ),
          const SizedBox(height: 4),
          Text(
            'Everything your store needs, in one place.',
            style: TextStyle(fontSize: 13.5, color: onAccent.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
