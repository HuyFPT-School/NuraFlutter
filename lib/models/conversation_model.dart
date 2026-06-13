import 'user_model.dart';

class ConversationModel {
  final String id;
  final dynamic user;
  final dynamic staff;
  final String subject;
  final String status;
  final int unreadByUser;
  final int unreadByStaff;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  ConversationModel({
    required this.id, this.user, this.staff, required this.subject,
    this.status = 'open', this.unreadByUser = 0, this.unreadByStaff = 0,
    this.lastMessageAt, this.createdAt,
  });

  String get statusText {
    switch (status) {
      case 'open': return 'Mở';
      case 'in_progress': return 'Đang xử lý';
      case 'resolved': return 'Đã giải quyết';
      case 'closed': return 'Đã đóng';
      default: return status;
    }
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    dynamic usr = json['user'];
    if (usr is Map<String, dynamic>) usr = UserModel.fromJson(usr);

    dynamic stf = json['staff'];
    if (stf is Map<String, dynamic>) stf = UserModel.fromJson(stf);

    return ConversationModel(
      id: json['_id'] ?? json['id'] ?? '',
      user: usr,
      staff: stf,
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'open',
      unreadByUser: (json['unreadByUser'] as num?)?.toInt() ?? 0,
      unreadByStaff: (json['unreadByStaff'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.tryParse(json['lastMessageAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
