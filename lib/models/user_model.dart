class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullname;
  final String? gender;
  final String? address;
  final DateTime? dateOfBirth;
  final String role;
  final bool isVerified;
  final String? avatar;
  final List<UserVoucher>? userVouchers;
  final List<String>? wishlist;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullname,
    this.gender,
    this.address,
    this.dateOfBirth,
    this.role = 'User',
    this.isVerified = false,
    this.avatar,
    this.userVouchers,
    this.wishlist,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      fullname: json['fullname'] ?? json['name'] ?? '',
      gender: json['gender'],
      address: json['address'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'].toString()) : null,
      role: json['role'] ?? 'User',
      isVerified: json['isVerified'] ?? false,
      avatar: json['avatar'],
      userVouchers: json['userVouchers'] != null
          ? (json['userVouchers'] as List).map((v) => UserVoucher.fromJson(v)).toList()
          : null,
      wishlist: json['wishlist'] != null
          ? (json['wishlist'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'phone': phone, 'fullname': fullname,
    'gender': gender, 'address': address, 'role': role,
    'isVerified': isVerified, 'avatar': avatar,
  };
}

class UserVoucher {
  final String voucherId;
  final int quantity;

  UserVoucher({required this.voucherId, this.quantity = 1});

  factory UserVoucher.fromJson(Map<String, dynamic> json) {
    return UserVoucher(
      voucherId: (json['voucherId'] is Map ? json['voucherId']['_id'] : json['voucherId']) ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }
}
