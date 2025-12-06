// lib/models/category.dart - SIMPLIFIÉ
class Category {
  final String id;
  final String name;
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory Category.empty() {
    return Category(
      id: '',
      name: 'Non catégorisé',
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name}';
  }
}