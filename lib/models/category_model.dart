class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? parentCategory;
  final List<String>? brands;

  CategoryModel({required this.id, required this.name, this.description, this.parentCategory, this.brands});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      parentCategory: json['parentCategory']?.toString(),
      brands: json['brands'] != null ? (json['brands'] as List).map((e) => e.toString()).toList() : null,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description};
}
