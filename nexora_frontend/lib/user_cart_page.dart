import 'package:flutter/material.dart';
import 'user_cart_manager.dart';
import 'payment_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class UserCartPage extends StatefulWidget {
  final String username;
  const UserCartPage({super.key, required this.username});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  final CartManager cart = CartManager();

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);

    if (cart.items.isEmpty) {
      return NxEmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Your cart is empty',
        message: 'Browse the shop and add something you like.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            itemCount: cart.items.length,
            itemBuilder: (_, i) {
              final item = cart.items[i];
              final p = item.product;
              return NxCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    NxIconBlock(icon: Icons.inventory_2_outlined, color: palette.primary, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                          const SizedBox(height: 2),
                          Text('\$${p.effectivePrice.toStringAsFixed(2)} each', style: TextStyle(fontSize: 12.5, color: palette.textMuted)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _qtyButton(Icons.remove_rounded, () => setState(() => cart.updateQuantity(p.id, item.quantity - 1))),
                              Container(
                                constraints: const BoxConstraints(minWidth: 40),
                                alignment: Alignment.center,
                                child: Text('${item.quantity}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                              ),
                              _qtyButton(Icons.add_rounded, () => setState(() => cart.updateQuantity(p.id, item.quantity + 1))),
                              const SizedBox(width: 12),
                              Text('Subtotal \$${(p.effectivePrice * item.quantity).toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.success)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    NxIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Remove',
                      color: palette.danger,
                      onTap: () => setState(() => cart.removeItem(p.id)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: palette.textMuted)),
                        Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: palette.success)),
                      ],
                    ),
                  ),
                  NxButton(
                    label: 'Proceed to payment',
                    icon: Icons.lock_outline_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            cartItems: cart.items,
                            totalAmount: cart.totalPrice,
                            username: widget.username,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    final palette = nxOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, size: 18, color: palette.textPrimary),
      ),
    );
  }
}
