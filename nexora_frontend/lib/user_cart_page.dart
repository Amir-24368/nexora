import 'package:flutter/material.dart';
import 'user_cart_manager.dart';
import 'payment_page.dart';

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
    if (cart.items.isEmpty) {
      return const Center(child: Text('Your cart is empty'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cart.items.length,
            itemBuilder: (_, i) {
              final item = cart.items[i];
              return ListTile(
                title: Text(item.product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$${item.product.effectivePrice.toStringAsFixed(2)} each'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => setState(() => cart.updateQuantity(item.product.id, item.quantity - 1)),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => cart.updateQuantity(item.product.id, item.quantity + 1)),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => cart.removeItem(item.product.id)),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade100, border: const Border(top: BorderSide(color: Colors.grey))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              ElevatedButton(
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
                child: const Text('Proceed to Payment'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}