import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'cancel_order_dialog.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String _activeFilter = 'all';
  final _expandedOrders = <String>{};

  final _filters = const [
    {'value': 'all', 'label': 'Tất cả', 'icon': Icons.inventory_2_outlined},
    {'value': 'pending_payment', 'label': 'Chờ thanh toán', 'icon': Icons.access_time_rounded},
    {'value': 'processing', 'label': 'Đang xử lý', 'icon': Icons.hourglass_top_rounded},
    {'value': 'shipped', 'label': 'Đang giao', 'icon': Icons.local_shipping_outlined},
    {'value': 'delivered', 'label': 'Đã giao', 'icon': Icons.check_circle_outline},
    {'value': 'cancelled', 'label': 'Đã hủy', 'icon': Icons.cancel_outlined},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  void _loadOrders() {
    final status = _activeFilter == 'all' ? null : _activeFilter;
    context.read<OrderProvider>().loadMyOrders(status: status);
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

  Future<void> _handleCancel(OrderModel order) async {
    final reason = await CancelOrderDialog.show(context);
    if (reason == null || reason.isEmpty || !mounted) return;

    final ok = await context.read<OrderProvider>().cancelOrder(order.id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã hủy đơn hàng thành công' : 'Không thể hủy đơn hàng'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Xác nhận nhận hàng thành công' : 'Không thể xác nhận'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tạo link thanh toán'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterTabs(),
            Expanded(child: _buildOrderList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đơn hàng của tôi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Quản lý và theo dõi đơn hàng của bạn',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _filters[i];
            final active = _activeFilter == f['value'];
            return GestureDetector(
              onTap: () {
                setState(() => _activeFilter = f['value'] as String);
                _loadOrders();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 16,
                      color: active ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return Consumer<OrderProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Đang tải đơn hàng...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                const SizedBox(height: 12),
                Text(provider.error!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loadOrders,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (provider.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Hãy bắt đầu mua sắm ngay nào!', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to products tab (index 0)
                    final homeState = context.findAncestorStateOfType<State>();
                    if (homeState != null && homeState.mounted) {
                      // Just switch to products tab
                    }
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Bắt đầu mua sắm'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(180, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _loadOrders(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildOrderCard(provider.orders[i]),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final expanded = _expandedOrders.contains(order.id);
    final color = _statusColor(order.orderStatus);
    final showPreview = !expanded && order.cartItems.length > 2;

    return Container(
      decoration: cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                Text(_orderIdShort(order.id), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (order.hasPreOrderItems) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Pre-Order', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange)),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(order.statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
          ),

          // Date
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_formatDate(order.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),

          // Items preview
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children: [
                ...((expanded ? order.cartItems : order.cartItems.take(2)).map((item) => _buildItemRow(item))),
                if (showPreview)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${order.cartItems.length - 2} sản phẩm khác',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),

          // Expanded details
          if (expanded) _buildExpandedDetails(order),

          const Divider(height: 1),

          // Summary row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_paymentMethodLabel(order.paymentMethod), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        order.paymentStatusText,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _paymentStatusColor(order.paymentStatus)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      _formatPrice(order.totalAmount),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          if (expanded) _buildActionButtons(order),

          // Expand toggle
          InkWell(
            onTap: () => setState(() {
              expanded ? _expandedOrders.remove(order.id) : _expandedOrders.add(order.id);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    expanded ? 'Ẩn chi tiết' : 'Xem chi tiết',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(item.imageUrl!, width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.surface, child: const Icon(Icons.image, color: AppColors.textSecondary)))
                : Container(width: 56, height: 56, color: AppColors.surface, child: const Icon(Icons.image, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('${_formatPrice(item.price)} × ${item.quantity}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(_formatPrice(item.price * item.quantity), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
                if (item.isPreOrder && item.itemStatus != 'available') ...[
                  const SizedBox(height: 4),
                  _buildItemStatusBadge(item),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemStatusBadge(OrderItem item) {
    String label;
    Color bgColor, textColor;
    switch (item.itemStatus) {
      case 'preorder_pending':
        label = 'Đang chờ nhập hàng';
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'preorder_ready':
      case 'shipped':
        label = 'Đã có hàng';
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        break;
      default:
        label = 'Có sẵn';
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildExpandedDetails(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        children: [
          // Pre-order notice
          if (order.hasPreOrderItems)
            _buildNotice(
              icon: Icons.info_outline,
              color: Colors.orange,
              text: order.preOrderNote ?? 'Đơn hàng có sản phẩm Pre-Order, có thể giao hàng theo từng phần.',
            ),

          // Payment failed notice
          if (order.orderStatus == 'pending_payment' || order.paymentStatus == 'failed')
            _buildNotice(
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              text: 'Thanh toán chưa hoàn tất. Vui lòng thử lại thanh toán hoặc đơn hàng sẽ bị hủy.',
            ),

          // Cancellation reason
          if (order.orderStatus == 'cancelled' && order.cancellationReason != null && order.cancellationReason!.isNotEmpty)
            _buildNotice(
              icon: Icons.info_outline,
              color: AppColors.error,
              text: 'Lý do hủy: ${order.cancellationReason}',
            ),

          // Shipping info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Text('Thông tin giao hàng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow('Số điện thoại', order.phone),
                _infoRow('Địa chỉ', order.shippingAddress),
                if (order.note != null && order.note!.isNotEmpty) _infoRow('Ghi chú', order.note!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice({required IconData icon, required Color color, required String text}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)))),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final canRetry = (order.orderStatus == 'pending_payment' || order.paymentStatus == 'failed') && order.paymentMethod != 'cod';
    final canCancel = order.orderStatus != 'shipped' && order.orderStatus != 'delivered' && order.orderStatus != 'cancelled';
    final canConfirm = order.orderStatus == 'shipped';

    if (!canRetry && !canCancel && !canConfirm) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        children: [
          if (canRetry) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleRetryPayment(order),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Thử lại thanh toán', style: TextStyle(fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (canCancel) const SizedBox(width: 8),
          ],
          if (canCancel)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleCancel(order),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Hủy đơn', style: TextStyle(fontSize: 12.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (canConfirm)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleConfirmDelivery(order),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Đã nhận hàng', style: TextStyle(fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
