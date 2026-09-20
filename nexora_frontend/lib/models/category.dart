class Category {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final List<Category> children;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.children = const [],
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      parentId: json['parent']?.toString(),
      children: json['children'] != null
          ? (json['children'] as List).map((c) => Category.fromJson(c)).toList()
          : [],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'parent': parentId,
      'is_active': isActive,
    };
  }
}