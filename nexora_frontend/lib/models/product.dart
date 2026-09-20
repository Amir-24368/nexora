import 'category.dart';
import 'shop.dart';

class Product {
  // ===== Basic Fields =====
  final String id;
  final String name;
  final String sku;
  final String? description;

  // ===== Brand as simple String =====
  final String? brand;

  // ===== Relationships =====
  final Category? category;

  // ===== Pricing =====
  final double purchasePrice;
  final double salePrice;
  final double? discountPercentage;
  final double taxPercentage;

  // ===== Volume/Date/Source =====
  final String volumeFrom;
  final String volumeTo;
  final String dateFrom;
  final String dateTo;
  final String source;

  // ===== Physical =====
  final double? weight;
  final double? length;
  final double? width;
  final double? height;

  // ===== Inventory =====
  final bool trackInventory;
  final int minimumStock;
  final int maximumStock;
  final int reorderPoint;

  // ===== Status =====
  final String status;
  final bool isActive;

  // ===== Business Intelligence =====
  final double rating;
  final int totalSales;
  final int viewsCount;
  final Map<String, dynamic> aiTags;

  // ===== Timestamps =====
  final DateTime createdAt;
  final DateTime updatedAt;

  // ===== Shop (for multi-tenant) =====
  final Shop? shop;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    this.brand,
    this.category,
    required this.purchasePrice,
    required this.salePrice,
    this.discountPercentage,
    this.taxPercentage = 0,
    this.volumeFrom = '',
    this.volumeTo = '',
    this.dateFrom = '',
    this.dateTo = '',
    this.source = '',
    this.weight,
    this.length,
    this.width,
    this.height,
    this.trackInventory = true,
    this.minimumStock = 0,
    this.maximumStock = 0,
    this.reorderPoint = 0,
    this.status = 'ACTIVE',
    this.isActive = true,
    this.rating = 0,
    this.totalSales = 0,
    this.viewsCount = 0,
    this.aiTags = const {},
    required this.createdAt,
    required this.updatedAt,
    this.shop,
  });

  /// Price after the discount percentage is applied (falls back to salePrice).
  double get effectivePrice {
    final pct = discountPercentage;
    if (pct == null || pct <= 0 || pct >= 100) return salePrice;
    return salePrice * (1 - pct / 100);
  }

  // ===== Safe parsers =====
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  // ===== fromJson =====
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      description: json['description'],
      brand: json['brand'],
      category: json['category_detail'] != null
          ? Category.fromJson(json['category_detail'] as Map<String, dynamic>)
          : null,
      purchasePrice: _parseDouble(json['purchase_price']) ?? 0,
      salePrice: _parseDouble(json['sale_price']) ?? 0,
      discountPercentage: _parseDouble(json['discount_percentage']),
      taxPercentage: _parseDouble(json['tax_percentage']) ?? 0,
      volumeFrom: json['volume_from'] ?? '',
      volumeTo: json['volume_to'] ?? '',
      dateFrom: json['date_from'] ?? '',
      dateTo: json['date_to'] ?? '',
      source: json['source'] ?? '',
      weight: _parseDouble(json['weight']),
      length: _parseDouble(json['length']),
      width: _parseDouble(json['width']),
      height: _parseDouble(json['height']),
      trackInventory: json['track_inventory'] ?? true,
      minimumStock: _parseInt(json['minimum_stock']) ?? 0,
      maximumStock: _parseInt(json['maximum_stock']) ?? 0,
      reorderPoint: _parseInt(json['reorder_point']) ?? 0,
      status: json['status'] ?? 'ACTIVE',
      isActive: json['is_active'] ?? true,
      rating: _parseDouble(json['rating']) ?? 0,
      totalSales: _parseInt(json['total_sales']) ?? 0,
      viewsCount: _parseInt(json['views_count']) ?? 0,
      aiTags: json['ai_tags'] ?? {},
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      shop: json['shop'] != null
          ? (json['shop'] is Map ? Shop.fromJson(json['shop'] as Map<String, dynamic>) : null)
          : null,
    );
  }

  // ===== toJson =====
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'brand': brand,
      'description': description,
      'category': category?.id,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'discount_percentage': discountPercentage,
      'tax_percentage': taxPercentage,
      'volume_from': volumeFrom,
      'volume_to': volumeTo,
      'date_from': dateFrom,
      'date_to': dateTo,
      'source': source,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'track_inventory': trackInventory,
      'minimum_stock': minimumStock,
      'maximum_stock': maximumStock,
      'reorder_point': reorderPoint,
      'status': status,
      'is_active': isActive,
    };
  }
}