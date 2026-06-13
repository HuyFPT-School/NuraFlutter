import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _api = ApiClient();

  Future<List<NotificationModel>> getNotifications({int limit = 20, int skip = 0}) async {
    final response = await _api.get(ApiConfig.notifications, queryParameters: {'limit': limit, 'skip': skip});
    final data = response.data;
    List list = data is List ? data : (data['notifications'] ?? data['data'] ?? []);
    return list.map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get(ApiConfig.unreadCount);
    final data = response.data;
    return data['unreadCount'] ?? data['count'] ?? 0;
  }

  Future<void> markAsRead(String id) async {
    await _api.patch(ApiConfig.markRead(id));
  }

  Future<void> markAllAsRead() async {
    await _api.patch(ApiConfig.markAllRead);
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete(ApiConfig.deleteNotification(id));
  }
}
