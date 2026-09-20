class PurchaseOrder {
  final String id;
  final String supplierName;
  final String status;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double discount;
  final double total;
  final String? notes;
  final DateTime createdAt;

  PurchaseOrder({
    required this.id,
    this.supplierName = '',
    this.status = 'DRAFT',
    this.subtotal = 0,
    this.tax = 0,
    this.shippingCost = 0,
    this.discount = 0,
    this.total = 0,
    this.notes,
    required this.createdAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier_detail'];
    return PurchaseOrder(
      id: json['id']?.toString() ?? '',
      supplierName: supplier is Map<String, dynamic> ? (supplier['name'] ?? '') : '',
      status: json['status'] ?? 'DRAFT',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0,
      shippingCost: double.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}