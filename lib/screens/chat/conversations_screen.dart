import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import 'chat_detail_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM').format(date);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return AppColors.success;
      case 'in_progress': return AppColors.warning;
      case 'resolved': return Colors.blue;
      case 'closed': return Colors.grey;
      default: return AppColors.textSecondary;
    }
  }

  void _showCreateDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo cuộc hội thoại mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: subjectController, label: 'Chủ đề', hint: 'Nhập chủ đề hỗ trợ'),
            const SizedBox(height: 12),
            CustomTextField(controller: messageController, label: 'Tin nhắn', hint: 'Mô tả vấn đề của bạn', maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.trim().isEmpty || messageController.text.trim().isEmpty) return;
              Navigator.pop(context);
              final provider = context.read<ChatProvider>();
              final id = await provider.createConversation(subjectController.text.trim(), messageController.text.trim());
              if (id != null && mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(conversationId: id)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Gửi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ')),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateDialog, child: const Icon(Icons.add)),
      body: Consumer<ChatProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.conversations.isEmpty) return const LoadingWidget();
          if (provider.conversations.isEmpty) {
            return const EmptyStateWidget(icon: Icons.chat_bubble_outline, title: 'Chưa có cuộc hội thoại', subtitle: 'Nhấn + để tạo mới');
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadConversations(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.conversations.length,
              itemBuilder: (_, i) {
                final conv = provider.conversations[i];
                return ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(conversationId: conv.id))),
                  leading: CircleAvatar(backgroundColor: AppColors.primaryLight, child: const Icon(Icons.support_agent, color: AppColors.primary)),
                  title: Text(conv.subject, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _statusColor(conv.status).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(conv.statusText, style: TextStyle(fontSize: 10, color: _statusColor(conv.status), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(_timeAgo(conv.lastMessageAt ?? conv.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  trailing: conv.unreadByUser > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: Text('${conv.unreadByUser}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      )
                    : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
