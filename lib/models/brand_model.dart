class BrandModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final List<String>? categories;

  BrandModel({required this.id, required this.name, this.description, this.logoUrl, this.categories});

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logoUrl'],
      categories: json['categories'] != null ? (json['categories'] as List).map((e) => e.toString()).toList() : null,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'logoUrl': logoUrl};
}
