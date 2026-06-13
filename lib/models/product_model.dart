import 'category_model.dart';
import 'brand_model.dart';
import 'user_model.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final String? description;
  final dynamic category;
  final dynamic brand;
  final String? tags;
  final int quantity;
  final List<String> imageUrl;
  final DateTime? expectedRestockDate;
  final bool allowPreOrder;
  final int maxPreOrderQuantity;
  final String? manufacture;
  final String? expiry;
  final String? storageInstructions;
  final String? instructionsForUse;
  final String? warning;
  final String? manufacturer;
  final String? appropriateAge;
  final double? weight;
  final List<Comment>? comments;

  ProductModel({
    required this.id, required this.name, required this.price,
    this.description, this.category, this.brand, this.tags,
    this.quantity = 0, this.imageUrl = const [],
    this.expectedRestockDate, this.allowPreOrder = true,
    this.maxPreOrderQuantity = 100, this.manufacture, this.expiry,
    this.storageInstructions, this.instructionsForUse, this.warning,
    this.manufacturer, this.appropriateAge, this.weight, this.comments,
  });

  bool get isOutOfStock => quantity <= 0;
  bool get canPreOrder => isOutOfStock && allowPreOrder;

  String get categoryName {
    if (category is CategoryModel) return (category as CategoryModel).name;
    if (category is Map) return category['name'] ?? '';
    return '';
  }

  String get brandName {
    if (brand is BrandModel) return (brand as BrandModel).name;
    if (brand is Map) return brand['name'] ?? '';
    return '';
  }

  double get averageRating {
    if (comments == null || comments!.isEmpty) return 0;
    return comments!.map((c) => c.rating).reduce((a, b) => a + b) / comments!.length;
  }

  String get firstImage => imageUrl.isNotEmpty ? imageUrl[0] : '';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    dynamic cat = json['category'];
    if (cat is Map<String, dynamic>) cat = CategoryModel.fromJson(cat);

    dynamic br = json['brand'];
    if (br is Map<String, dynamic>) br = BrandModel.fromJson(br);

    List<String> images = [];
    if (json['imageUrl'] != null) {
      if (json['imageUrl'] is List) {
        images = (json['imageUrl'] as List).map((e) => e.toString()).toList();
      } else if (json['imageUrl'] is String) {
        images = [json['imageUrl'].toString()];
      }
    }

    List<Comment>? commentsList;
    if (json['comments'] != null && json['comments'] is List) {
      commentsList = (json['comments'] as List).map((c) => Comment.fromJson(c)).toList();
    }

    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description'],
      category: cat,
      brand: br,
      tags: json['tags'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: images,
      expectedRestockDate: json['expectedRestockDate'] != null ? DateTime.tryParse(json['expectedRestockDate'].toString()) : null,
      allowPreOrder: json['allowPreOrder'] ?? true,
      maxPreOrderQuantity: (json['maxPreOrderQuantity'] as num?)?.toInt() ?? 100,
      manufacture: json['manufacture'],
      expiry: json['expiry'],
      storageInstructions: json['storageInstructions'],
      instructionsForUse: json['instructionsForUse'],
      warning: json['warning'],
      manufacturer: json['manufacturer'],
      appropriateAge: json['appropriateAge'],
      weight: (json['weight'] as num?)?.toDouble(),
      comments: commentsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'price': price, 'description': description,
    'quantity': quantity, 'imageUrl': imageUrl,
  };
}

class Comment {
  final String? id;
  final int rating;
  final String content;
  final dynamic author;
  final DateTime? createdAt;

  Comment({this.id, required this.rating, required this.content, this.author, this.createdAt});

  String get authorName {
    if (author is UserModel) return (author as UserModel).fullname;
    if (author is Map) return author['fullname'] ?? author['name'] ?? 'Ẩn danh';
    return 'Ẩn danh';
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    dynamic auth = json['author'];
    if (auth is Map<String, dynamic>) auth = UserModel.fromJson(auth);

    return Comment(
      id: json['_id'] ?? json['id'],
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      content: json['content'] ?? '',
      author: auth,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
