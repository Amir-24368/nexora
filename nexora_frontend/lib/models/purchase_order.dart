class PurchaseOrderLine {
  final String id;
  final String productId;
  final String productName;
  final String productSku;
  final int orderedQuantity;
  final int receivedQuantity;
  final double purchasePrice;
  final double subtotal;

  PurchaseOrderLine({
    required this.id,
    this.productId = '',
    this.productName = '',
    this.productSku = '',
    this.orderedQuantity = 0,
    this.receivedQuantity = 0,
    this.purchasePrice = 0,
    this.subtotal = 0,
  });

  int get remaining => orderedQuantity - receivedQuantity;

  bool get fullyReceived => receivedQuantity >= orderedQuantity;

  factory PurchaseOrderLine.fromJson(Map<String, dynamic> json) {
    final product = json['product_detail'];
    return PurchaseOrderLine(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      productName: product is Map<String, dynamic> ? (product['name'] ?? '') : '',
      productSku: product is Map<String, dynamic> ? (product['sku'] ?? '') : '',
      orderedQuantity: int.tryParse(json['ordered_quantity']?.toString() ?? '') ?? 0,
      receivedQuantity: int.tryParse(json['received_quantity']?.toString() ?? '') ?? 0,
      purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '') ?? 0,
    );
  }
}

class PurchaseOrder {
  final String id;
  final String supplierId;
  final String supplierName;
  final String status;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double discount;
  final double total;
  final String? notes;
  final DateTime? expectedDelivery;
  final DateTime createdAt;
  final List<PurchaseOrderLine> lines;

  PurchaseOrder({
    required this.id,
    this.supplierId = '',
    this.supplierName = '',
    this.status = 'DRAFT',
    this.subtotal = 0,
    this.tax = 0,
    this.shippingCost = 0,
    this.discount = 0,
    this.total = 0,
    this.notes,
    this.expectedDelivery,
    required this.createdAt,
    this.lines = const [],
  });

  int get totalOrdered => lines.fold(0, (sum, line) => sum + line.orderedQuantity);

  int get totalReceived => lines.fold(0, (sum, line) => sum + line.receivedQuantity);

  bool get fullyReceived =>
      status == 'RECEIVED' || (lines.isNotEmpty && lines.every((line) => line.fullyReceived));

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier_detail'];
    final linesData = json['lines'];
    return PurchaseOrder(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplier']?.toString() ?? '',
      supplierName: supplier is Map<String, dynamic> ? (supplier['name'] ?? '') : '',
      status: json['status'] ?? 'DRAFT',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0,
      shippingCost: double.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      notes: json['notes'],
      expectedDelivery: json['expected_delivery'] != null
          ? DateTime.tryParse(json['expected_delivery'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lines: linesData is List
          ? linesData
              .whereType<Map<String, dynamic>>()
              .map((line) => PurchaseOrderLine.fromJson(line))
              .toList()
          : const [],
    );
  }
}