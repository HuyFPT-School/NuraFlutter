class CartItemModel {
  final String productId;
  final String name;
  final double price;
  final double? salePrice;
  final String? imageUrl;
  int quantity;
  final int availableStock;
  final bool isPreOrder;

  CartItemModel({
    required this.productId, required this.name, required this.price,
    this.salePrice, this.imageUrl, this.quantity = 1,
    this.availableStock = 999, this.isPreOrder = false,
  });

  double get effectivePrice => salePrice ?? price;
  double get totalPrice => effectivePrice * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      availableStock: (json['availableStock'] as num?)?.toInt() ?? 999,
      isPreOrder: json['isPreOrder'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId, 'name': name, 'price': price,
    'salePrice': salePrice, 'imageUrl': imageUrl,
    'quantity': quantity, 'availableStock': availableStock,
    'isPreOrder': isPreOrder,
  };
}
