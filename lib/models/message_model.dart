import 'user_model.dart';

class MessageModel {
  final String id;
  final String conversation;
  final dynamic sender;
  final String senderRole;
  final String content;
  final DateTime? createdAt;

  MessageModel({
    required this.id, required this.conversation, this.sender,
    required this.senderRole, required this.content, this.createdAt,
  });

  String get senderName {
    if (sender is UserModel) return (sender as UserModel).fullname;
    if (sender is Map) return sender['fullname'] ?? sender['name'] ?? '';
    return '';
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    dynamic s = json['sender'];
    if (s is Map<String, dynamic>) s = UserModel.fromJson(s);

    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      conversation: json['conversation']?.toString() ?? '',
      sender: s,
      senderRole: json['senderRole'] ?? 'user',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
