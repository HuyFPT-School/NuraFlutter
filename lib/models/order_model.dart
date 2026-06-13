class OrderModel {
  final String id;
  final dynamic customer;
  final List<OrderItem> cartItems;
  final String shippingAddress;
  final String phone;
  final String? note;
  final String? cancellationReason;
  final double totalAmount;
  final bool hasPreOrderItems;
  final String? preOrderNote;
  final String? voucherUsed;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id, this.customer, required this.cartItems,
    required this.shippingAddress, required this.phone, this.note,
    this.cancellationReason, required this.totalAmount,
    this.hasPreOrderItems = false, this.preOrderNote, this.voucherUsed,
    this.paymentMethod = 'cod', this.paymentStatus = 'pending',
    this.orderStatus = 'processing', this.createdAt, this.updatedAt,
  });

  String get statusText {
    switch (orderStatus) {
      case 'pending_payment': return 'Chờ thanh toán';
      case 'processing': return 'Đang xử lý';
      case 'shipped': return 'Đang giao';
      case 'delivered': return 'Đã giao';
      case 'cancelled': return 'Đã hủy';
      default: return orderStatus;
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case 'pending': return 'Chờ thanh toán';
      case 'paid': return 'Đã thanh toán';
      case 'failed': return 'Thất bại';
      default: return paymentStatus;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];
    if (json['cartItems'] != null) {
      items = (json['cartItems'] as List).map((e) => OrderItem.fromJson(e)).toList();
    }
    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      customer: json['customer'],
      cartItems: items,
      shippingAddress: json['shippingAddress'] ?? '',
      phone: json['phone'] ?? '',
      note: json['note'],
      cancellationReason: json['cancellationReason'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      hasPreOrderItems: json['hasPreOrderItems'] ?? false,
      preOrderNote: json['preOrderNote'],
      voucherUsed: json['voucherUsed']?.toString(),
      paymentMethod: json['paymentMethod'] ?? 'cod',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      orderStatus: json['orderStatus'] ?? 'processing',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }
}

class OrderItem {
  final String? product;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final bool isPreOrder;
  final DateTime? expectedAvailableDate;
  final String itemStatus;

  OrderItem({
    this.product, required this.name, required this.price,
    required this.quantity, this.imageUrl, this.isPreOrder = false,
    this.expectedAvailableDate, this.itemStatus = 'available',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: json['product']?.toString(),
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: json['imageUrl'],
      isPreOrder: json['isPreOrder'] ?? false,
      expectedAvailableDate: json['expectedAvailableDate'] != null
          ? DateTime.tryParse(json['expectedAvailableDate'].toString()) : null,
      itemStatus: json['itemStatus'] ?? 'available',
    );
  }
}
