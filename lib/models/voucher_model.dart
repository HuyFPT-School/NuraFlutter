class VoucherModel {
  final String id;
  final String code;
  final double discountPercentage;
  final String? description;
  final double minOrderValue;
  final DateTime? expiryDate;
  final bool isActive;

  VoucherModel({
    required this.id, required this.code, required this.discountPercentage,
    this.description, this.minOrderValue = 0, this.expiryDate, this.isActive = true,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      description: json['description'],
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) : null,
      isActive: json['isActive'] ?? true,
    );
  }
}
