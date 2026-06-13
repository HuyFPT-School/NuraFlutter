import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  static const int _limit = 20;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _skip = 0;
      _hasMore = true;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.getNotifications(limit: _limit, skip: _skip);
      if (refresh) {
        _notifications = result;
      } else {
        _notifications.addAll(result);
      }
      _hasMore = result.length >= _limit;
      _skip += result.length;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index >= 0 && !_notifications[index].isRead) {
        _notifications[index].isRead = true;
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      for (var n in _notifications) { n.isRead = true; }
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      final n = _notifications.firstWhere((n) => n.id == id);
      if (!n.isRead) _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
      await _service.deleteNotification(id);
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await loadNotifications();
  }
}
