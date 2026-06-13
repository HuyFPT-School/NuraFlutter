import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/loading_widget.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  const ChatDetailScreen({super.key, required this.conversationId});
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openConversation(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return AppColors.success;
      case 'in_progress': return AppColors.warning;
      case 'resolved': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, provider, __) {
        final conv = provider.activeConversation;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conv?.subject ?? 'Đang tải...', style: const TextStyle(fontSize: 16)),
                if (conv != null) Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: _statusColor(conv.status).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(conv.statusText, style: TextStyle(fontSize: 10, color: _statusColor(conv.status), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          body: provider.isLoading && provider.messages.isEmpty
            ? const LoadingWidget()
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.messages.length,
                      itemBuilder: (_, i) {
                        final msg = provider.messages[i];
                        final isUser = msg.senderRole == 'user';

                        // Date separator
                        Widget? dateSep;
                        if (i == 0 || (msg.createdAt != null && provider.messages[i - 1].createdAt != null &&
                            DateFormat('yyyyMMdd').format(msg.createdAt!) != DateFormat('yyyyMMdd').format(provider.messages[i - 1].createdAt!))) {
                          dateSep = Center(child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              msg.createdAt != null ? DateFormat('dd/MM/yyyy').format(msg.createdAt!) : '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ));
                        }

                        return Column(
                          children: [
                            if (dateSep != null) dateSep,
                            Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.primary : const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(msg.content, style: TextStyle(fontSize: 14, color: isUser ? Colors.white : AppColors.textPrimary, height: 1.4)),
                                    const SizedBox(height: 4),
                                    Text(
                                      msg.createdAt != null ? DateFormat('HH:mm').format(msg.createdAt!) : '',
                                      style: TextStyle(fontSize: 10, color: isUser ? Colors.white70 : AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(12, 8, 8, MediaQuery.of(context).padding.bottom + 8),
                    decoration: const BoxDecoration(color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border))),
                    child: Row(children: [
                      Expanded(child: TextField(
                        controller: _messageController,
                        maxLines: 4, minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...', border: InputBorder.none,
                          filled: true, fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      )),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage),
                      ),
                    ]),
                  ),
                ],
              ),
        );
      },
    );
  }
}
