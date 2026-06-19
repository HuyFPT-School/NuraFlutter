import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'cancel_order_dialog.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment': return AppColors.warning;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.deepPurple;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case 'paid': return AppColors.success;
      case 'failed': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'momo': return 'Ví MoMo';
      case 'vnpay': return 'VNPay';
      default: return 'Thanh toán khi nhận hàng (COD)';
    }
  }

  String _formatPrice(double price) {
    final f = NumberFormat('#,###', 'vi_VN');
    return '${f.format(price)} ₫';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy, HH:mm').format(dt.toLocal());
  }

  String _orderIdShort(String id) {
    return '#${id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase()}';
  }

  String _itemStatusLabel(String status) {
    switch (status) {
      case 'preorder_pending': return 'Đang chờ nhập hàng';
      case 'preorder_ready':
      case 'shipped': return 'Đã có hàng';
      default: return 'Có sẵn';
    }
  }

  Color _itemStatusColor(String status) {
    switch (status) {
      case 'preorder_pending': return Colors.orange;
      case 'preorder_ready':
      case 'shipped': return AppColors.success;
      default: return Colors.blue;
    }
  }

  Future<void> _handleCancel(OrderModel order) async {
    final reason = await CancelOrderDialog.show(context);
    if (reason == null || reason.isEmpty || !mounted) return;
    final ok = await context.read<OrderProvider>().cancelOrder(order.id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Đã hủy đơn hàng thành công' : 'Không thể hủy đơn hàng'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    }
  }

  Future<void> _handleConfirmDelivery(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xác nhận nhận hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Bạn đã nhận được đơn hàng này?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Chưa')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(0, 40)),
            child: const Text('Đã nhận hàng'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await context.read<OrderProvider>().confirmDelivery(order.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Xác nhận nhận hàng thành công' : 'Không thể xác nhận'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    }
  }

  Future<void> _handleRetryPayment(OrderModel order) async {
    try {
      final result = await context.read<OrderProvider>().retryPayment(order.id);
      if (!mounted) return;
      if (result != null && result['paymentUrl'] != null) {
        Navigator.pushNamed(context, AppRoutes.paymentWebview, arguments: result['paymentUrl']);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không thể tạo link thanh toán'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Consumer<OrderProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final order = provider.selectedOrder;
          if (order == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('Không tìm thấy đơn hàng', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return _buildContent(order);
        },
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    final color = _statusColor(order.orderStatus);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Order status header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(_statusIcon(order.orderStatus), color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(order.statusText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                ),
                const SizedBox(height: 8),
                Text('Mã đơn: ${_orderIdShort(order.id)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(_formatDate(order.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (order.hasPreOrderItems) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('Có sản phẩm Pre-Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Notices
          if (order.hasPreOrderItems)
            _buildNoticeCard(
              icon: Icons.info_outline,
              color: Colors.orange,
              text: order.preOrderNote ?? 'Đơn hàng có sản phẩm Pre-Order, có thể giao hàng theo từng phần.',
            ),
          if (order.orderStatus == 'pending_payment' || order.paymentStatus == 'failed')
            _buildNoticeCard(
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              text: 'Thanh toán chưa hoàn tất. Vui lòng thử lại thanh toán.',
            ),
          if (order.orderStatus == 'cancelled' && order.cancellationReason != null && order.cancellationReason!.isNotEmpty)
            _buildNoticeCard(
              icon: Icons.info_outline,
              color: AppColors.error,
              text: 'Lý do hủy: ${order.cancellationReason}',
            ),

          // Cart items
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Sản phẩm (${order.cartItems.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 20),
                ...order.cartItems.map((item) => _buildDetailItem(item)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Shipping info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Thông tin giao hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 20),
                _detailRow(Icons.phone_outlined, 'Số điện thoại', order.phone),
                _detailRow(Icons.location_on_outlined, 'Địa chỉ', order.shippingAddress),
                if (order.note != null && order.note!.isNotEmpty)
                  _detailRow(Icons.note_outlined, 'Ghi chú', order.note!),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Payment summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration,
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Thanh toán', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 20),
                _summaryRow('Phương thức', _paymentMethodLabel(order.paymentMethod)),
                _summaryRow('Trạng thái', order.paymentStatusText, valueColor: _paymentStatusColor(order.paymentStatus)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(_formatPrice(order.totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          _buildActions(order),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending_payment': return Icons.access_time_rounded;
      case 'processing': return Icons.hourglass_top_rounded;
      case 'shipped': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.inventory_2;
    }
  }

  Widget _buildNoticeCard({required IconData icon, required Color color, required String text}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color.withOpacity(0.9)))),
        ],
      ),
    );
  }

  Widget _buildDetailItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(item.imageUrl!, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${_formatPrice(item.price)} × ${item.quantity}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.isPreOrder && item.itemStatus != 'available') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _itemStatusColor(item.itemStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_itemStatusLabel(item.itemStatus),
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _itemStatusColor(item.itemStatus))),
                      ),
                    ],
                    const Spacer(),
                    Text(_formatPrice(item.price * item.quantity),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
                if (item.isPreOrder && item.itemStatus == 'preorder_pending' && item.expectedAvailableDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('Dự kiến: ${DateFormat('dd/MM/yyyy').format(item.expectedAvailableDate!)}',
                        style: const TextStyle(fontSize: 11, color: Colors.orange)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.image, color: AppColors.textSecondary),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActions(OrderModel order) {
    final canRetry = (order.orderStatus == 'pending_payment' || order.paymentStatus == 'failed') && order.paymentMethod != 'cod';
    final canCancel = order.orderStatus != 'shipped' && order.orderStatus != 'delivered' && order.orderStatus != 'cancelled';
    final canConfirm = order.orderStatus == 'shipped';

    if (!canRetry && !canCancel && !canConfirm) return const SizedBox.shrink();

    return Column(
      children: [
        if (canRetry)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleRetryPayment(order),
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Thử lại thanh toán'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        if (canRetry && (canCancel || canConfirm)) const SizedBox(height: 10),
        if (canConfirm)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleConfirmDelivery(order),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Đã nhận hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        if (canConfirm && canCancel) const SizedBox(height: 10),
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleCancel(order),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Hủy đơn hàng'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }
}
