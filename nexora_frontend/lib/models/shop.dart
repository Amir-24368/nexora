class Shop {
  final String id;
  final String name;
  final String? slug;
  final String? taxId;
  final String? phone;
  final String? address;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;

  Shop({
    required this.id,
    required this.name,
    this.slug,
    this.taxId,
    this.phone,
    this.address,
    this.logoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      slug: json['slug'],
      taxId: json['tax_id'],
      phone: json['phone'],
      address: json['address'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}