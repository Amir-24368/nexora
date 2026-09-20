class Customer {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? address;
  final int totalPurchases;
  final double totalSpent;

  // ===== RFM (backend-computed, read-only) =====
  final int recencyDays;
  final int frequency;
  final double monetary;
  final int rfmScore;
  final String? rfmSegment;

  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.fullName,
    this.phone = '',
    this.email,
    this.address,
    this.totalPurchases = 0,
    this.totalSpent = 0,
    this.recencyDays = 0,
    this.frequency = 0,
    this.monetary = 0,
    this.rfmScore = 0,
    this.rfmSegment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'],
      totalPurchases: int.tryParse(json['total_purchases']?.toString() ?? '') ?? 0,
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0,
      recencyDays: int.tryParse(json['recency_days']?.toString() ?? '') ?? 0,
      frequency: int.tryParse(json['frequency']?.toString() ?? '') ?? 0,
      monetary: double.tryParse(json['monetary']?.toString() ?? '0') ?? 0,
      rfmScore: int.tryParse(json['rfm_score']?.toString() ?? '') ?? 0,
      rfmSegment: json['rfm_segment'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}