import 'models/product.dart';

class CartItem {
  Product product;
  int quantity;
  CartItem({required this.product, required this.quantity});
}

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