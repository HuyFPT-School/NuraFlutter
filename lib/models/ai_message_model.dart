import 'product_model.dart';

class AiMessageModel {
  final String role;
  final String content;
  final DateTime timestamp;
  final List<ProductModel> suggestedProducts;

  AiMessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
    this.suggestedProducts = const [],
  });

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    List<ProductModel> products = [];
    if (json['suggestedProducts'] != null && json['suggestedProducts'] is List) {
      products = (json['suggestedProducts'] as List)
          .map((p) => ProductModel.fromJson(p is Map<String, dynamic> ? Map<String, dynamic>.from(p) : {}))
          .toList();
    }
    return AiMessageModel(
      role: json['role'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      suggestedProducts: products,
    );
  }
}
