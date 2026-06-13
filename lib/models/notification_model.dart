class NotificationModel {
  final String id;
  final String user;
  final String type;
  final String title;
  final String message;
  final String? orderId;
  final dynamic data;
  bool isRead;
  final String? link;
  final DateTime? createdAt;

  NotificationModel({
    required this.id, required this.user, required this.type,
    required this.title, required this.message, this.orderId,
    this.data, this.isRead = false, this.link, this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      user: json['user']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      orderId: json['orderId']?.toString(),
      data: json['data'],
      isRead: json['isRead'] ?? false,
      link: json['link'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
