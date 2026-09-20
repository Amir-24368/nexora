import 'customer.dart';
import 'product.dart';

class Sale {
  final String id;
  final Customer? customer;
  final double totalAmount;
  final DateTime saleDate;
  final String status;
  final String paymentStatus;
  final List<SaleItem> items;

  Sale({
    required this.id,
    this.customer,
    required this.totalAmount,
    required this.saleDate,
    this.status = 'PENDING',
    this.paymentStatus = 'UNPAID',
    this.items = const [],
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'].toString(),
      customer: json['customer_detail'] != null
          ? Customer.fromJson(json['customer_detail'] as Map<String, dynamic>)
          : null,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      saleDate: DateTime.tryParse(json['sale_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'PENDING',
      paymentStatus: json['payment_status'] ?? 'UNPAID',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => SaleItem.fromJson(i as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class SaleItem {
  final String id;
  final Product? product;
  final int quantity;
  final double price;

  SaleItem({
    required this.id,
    this.product,
    required this.quantity,
    required this.price,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    // The backend sends the product primary key under 'product' and the full
    // object under 'product_detail'. Parsing the raw PK as a Product crashed.
    final detail = json['product_detail'];
    return SaleItem(
      id: json['id']?.toString() ?? '',
      product: detail is Map<String, dynamic> ? Product.fromJson(detail) : null,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }
}