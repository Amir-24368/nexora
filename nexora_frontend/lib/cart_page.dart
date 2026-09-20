import 'package:flutter/material.dart';
import 'dart:io';
import 'shopping_page.dart';

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void addItem(Product product) {
    int index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
  }

  void updateQuantity(String productId, int newQuantity) {
    int index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
    }
  }

  void clearCart() {
    _items.clear();
  }

  double get totalPrice => _items.fold(0, (sum, item) => sum + (item.product.effectivePrice * item.quantity));
}

class CartItem {
  Product product;
  int quantity;
  CartItem({required this.product, required this.quantity});
}

class CartPage extends StatefulWidget {
  final List<Product> products;
  const CartPage({super.key, required this.products});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager cart = CartManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              setState(() {
                cart.clearCart();
              });
            },
          ),
        ],
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      final hasOff = item.product.offPrice != null && item.product.offPrice! < item.product.price;
                      final displayPrice = item.product.effectivePrice;
                      return ListTile(
                        leading: item.product.imagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(item.product.imagePath!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image),
                              ),
                        title: Text(item.product.cName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasOff)
                              Row(
                                children: [
                                  Text('\$${item.product.price.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                                ],
                              )
                            else
                              Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                            Text('Qty: ${item.quantity}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  cart.updateQuantity(item.product.id, item.quantity - 1);
                                });
                              },
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  cart.updateQuantity(item.product.id, item.quantity + 1);
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  cart.removeItem(item.product.id);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '\$${cart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Proceed to checkout (demo)')),
                          );
                        },
                        child: const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}