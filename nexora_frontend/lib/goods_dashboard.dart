import 'package:flutter/material.dart';
import 'goods_management_page.dart';
import 'goods_info_management_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class GoodsDashboard extends StatelessWidget {
  const GoodsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Goods'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NxSectionHeader(title: 'Goods workspace', subtitle: 'Choose what you want to manage'),
                const SizedBox(height: 8),
                NxCard(
                  padding: const EdgeInsets.all(18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoodsManagementPage()),
                  ),
                  child: Row(
                    children: [
                      const NxIconBlock(icon: Icons.inventory_2_rounded, color: Color(0xFF0EAF7B)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                            const SizedBox(height: 3),
                            Text('Add, edit, delete products & prices', style: TextStyle(fontSize: 13, color: palette.textMuted)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: palette.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                NxCard(
                  padding: const EdgeInsets.all(18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoodsInfoManagementPage()),
                  ),
                  child: Row(
                    children: [
                      const NxIconBlock(icon: Icons.analytics_outlined, color: Color(0xFF3B9DDB)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Movement insight', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                            const SizedBox(height: 3),
                            Text('Track buying & selling volumes', style: TextStyle(fontSize: 13, color: palette.textMuted)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: palette.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
