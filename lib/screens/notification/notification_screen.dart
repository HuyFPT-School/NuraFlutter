import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications(refresh: true);
    });
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order_created': return Icons.shopping_bag_outlined;
      case 'order_status_changed': return Icons.sync;
      case 'preorder_ready': return Icons.inventory_2_outlined;
      case 'payment_success': return Icons.payment;
      case 'payment_failed': return Icons.payment;
      case 'order_delivered': return Icons.local_shipping;
      case 'order_cancelled': return Icons.cancel_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'payment_success': case 'order_delivered': return AppColors.success;
      case 'payment_failed': case 'order_cancelled': return AppColors.error;
      case 'preorder_ready': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) => provider.notifications.isNotEmpty
              ? TextButton(onPressed: () => provider.markAllAsRead(), child: const Text('Đọc tất cả', style: TextStyle(color: AppColors.primary)))
              : const SizedBox(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.notifications.isEmpty) return const LoadingWidget();
          if (provider.notifications.isEmpty) {
            return const EmptyStateWidget(icon: Icons.notifications_off_outlined, title: 'Không có thông báo');
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadNotifications(refresh: true),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollEndNotification && n.metrics.extentAfter < 100) provider.loadMore();
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.notifications.length,
                itemBuilder: (_, i) {
                  final n = provider.notifications[i];
                  return Dismissible(
                    key: Key(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      color: AppColors.error.withOpacity(0.1),
                      child: const Icon(Icons.delete, color: AppColors.error),
                    ),
                    onDismissed: (_) => provider.deleteNotification(n.id),
                    child: InkWell(
                      onTap: () => provider.markAsRead(n.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.white : AppColors.primaryLight,
                          border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: _getIconColor(n.type).withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(_getIcon(n.type), size: 22, color: _getIconColor(n.type)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: TextStyle(fontSize: 14, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(_timeAgo(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            )),
                            if (!n.isRead)
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
