import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/ai_message_model.dart';
import '../../models/product_model.dart';
import '../../widgets/custom_button.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiProvider>().init();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatVND(double price) {
    return '${NumberFormat('#,###', 'vi_VN').format(price).replaceAll(',', '.')}₫';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI NURA'),
        actions: [
          if (auth.isAuthenticated)
            Consumer<AiProvider>(
              builder: (_, ai, __) => ai.messages.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Xóa cuộc trò chuyện'),
                          content: const Text('Bạn có chắc muốn xóa tất cả lịch sử chat với AI?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                            TextButton(
                              onPressed: () {
                                ai.clearHistory();
                                Navigator.pop(context);
                              },
                              child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
        ],
      ),
      body: !auth.isAuthenticated
          ? _buildGuestState()
          : Consumer<AiProvider>(
              builder: (context, ai, _) {
                // Scroll to bottom after frame
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return Column(
                  children: [
                    Expanded(
                      child: ai.messages.isEmpty && !ai.isLoading
                          ? _buildWelcomeState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: ai.messages.length,
                              itemBuilder: (_, index) {
                                final message = ai.messages[index];
                                return _buildMessageBubble(message);
                              },
                            ),
                    ),
                    if (ai.error != null)
                      Container(
                        color: AppColors.error.withOpacity(0.05),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(ai.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    _buildInputBar(ai),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Trò chuyện với Trợ lý AI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đăng nhập để đặt câu hỏi trực tiếp cho AI và nhận tư vấn về dinh dưỡng, lựa chọn loại sữa phù hợp nhất cho bé yêu của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Đăng nhập ngay',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              child: const Text('Đăng ký tài khoản', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assistant, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Xin chào mẹ bé! 👋',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tôi là trợ lý ảo AI thông minh của NURA. Tôi có thể giúp bạn giải đáp những thắc mắc nào hôm nay?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          _buildPromptSuggestion('Sữa nào tốt nhất cho trẻ sơ sinh 0-6 tháng tuổi?'),
          _buildPromptSuggestion('Bé bị dị ứng sữa bò thì nên dùng loại sữa nào?'),
          _buildPromptSuggestion('Cách pha sữa bột công thức đúng chuẩn dinh dưỡng?'),
        ],
      ),
    );
  }

  Widget _buildPromptSuggestion(String prompt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          _messageController.text = prompt;
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.question_answer_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessageModel message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.assistant, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!isUser && message.suggestedProducts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 32, top: 12, bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.warning, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Sản phẩm khuyên dùng cho bạn:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              height: 185,
              padding: const EdgeInsets.only(left: 32),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.suggestedProducts.length,
                itemBuilder: (_, i) {
                  final product = message.suggestedProducts[i];
                  return _buildProductCard(product);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product.id),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: cardDecoration.copyWith(
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: product.firstImage,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 90,
                  color: AppColors.surface,
                  child: const Icon(Icons.image, color: AppColors.textSecondary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatVND(product.price),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(AiProvider ai) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi tại đây...',
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 24,
            child: ai.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        ai.sendMessage(text);
                        _messageController.clear();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
