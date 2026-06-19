import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/staff_service.dart';

class StaffOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const StaffOrderDetailScreen({super.key, required this.order});
  @override
  State<StaffOrderDetailScreen> createState() => _StaffOrderDetailScreenState();
}

class _StaffOrderDetailScreenState extends State<StaffOrderDetailScreen> {
  final _staffService = StaffService();
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  late Map<String, dynamic> _order;
  bool _isUpdating = false;

  final _statusFlow = ['pending_payment', 'processing', 'shipped', 'delivered'];
  final _statusLabels = {
    'pending_payment': 'Chờ thanh toán',
    'processing': 'Chờ xử lý',
    'shipped': 'Đang giao',
    'delivered': 'Đã giao',
    'cancelled': 'Đã hủy',
  };
  final _paymentStatusLabels = {
    'pending': 'Chưa thanh toán',
    'paid': 'Đã thanh toán',
    'failed': 'Thanh toán lỗi',
  };

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _order['_id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng #$shortId'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusTimeline(),
              const SizedBox(height: 16),
              _buildCustomerInfo(),
              const SizedBox(height: 16),
              _buildProductsList(),
              const SizedBox(height: 16),
              _buildPaymentInfo(),
              const SizedBox(height: 16),
              if (_order['note'] != null && _order['note'].toString().isNotEmpty)
                _buildNoteSection(),
              const SizedBox(height: 16),
              _buildActions(),
              const SizedBox(height: 32),
            ],
          ),
          if (_isUpdating)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final currentStatus = _order['orderStatus']?.toString() ?? 'processing';
    final isCancelled = currentStatus == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Trạng thái đơn hàng',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Đơn hàng đã bị hủy',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error),
                  ),
                ],
              ),
            )
          else
            Row(
              children: List.generate(_statusFlow.length * 2 - 1, (index) {
                if (index.isOdd) {
                  final prevIdx = index ~/ 2;
                  final currentIdx = _statusFlow.indexOf(currentStatus);
                  final isCompleted = prevIdx < currentIdx;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isCompleted ? AppColors.success : AppColors.border,
                    ),
                  );
                }
                final stepIdx = index ~/ 2;
                final stepStatus = _statusFlow[stepIdx];
                final currentIdx = _statusFlow.indexOf(currentStatus);
                final isCompleted = stepIdx <= currentIdx;

                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.success : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? AppColors.success : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : _getStatusIcon(stepStatus),
                        size: 18,
                        color: isCompleted ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusLabels[stepStatus] ?? stepStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                        color: isCompleted ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'processing':
        return Icons.hourglass_empty;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.inventory_2_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildCustomerInfo() {
    final name = _order['customer']?['fullname'] ?? 'N/A';
    final phone = _order['phone'] ?? _order['customer']?['phone'] ?? 'N/A';
    final address = _order['shippingAddress'] ?? 'N/A';

    return _buildSection(
      title: 'Thông tin khách hàng',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _infoRow(Icons.person, 'Họ tên', name.toString()),
          const SizedBox(height: 10),
          _infoRow(Icons.phone_outlined, 'Số điện thoại', phone.toString()),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on_outlined, 'Địa chỉ', address.toString()),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    final items = _order['cartItems'] as List<dynamic>? ?? [];

    return _buildSection(
      title: 'Sản phẩm (${items.length})',
      icon: Icons.shopping_bag_outlined,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index] as Map<String, dynamic>;
          final product = item['product'] as Map<String, dynamic>? ?? {};
          final name = item['name'] ?? product['name'] ?? 'Sản phẩm';
          final quantity = item['quantity'] ?? 1;
          final price = item['price'] ?? 0;
          final imageUrlList = product['imageUrl'];
          final image = item['imageUrl'] ?? (imageUrlList is List && imageUrlList.isNotEmpty ? imageUrlList[0] : imageUrlList);

          return Container(
            margin: EdgeInsets.only(bottom: index < items.length - 1 ? 10 : 0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image != null
                      ? Image.network(
                          image.toString(),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildProductPlaceholder(),
                        )
                      : _buildProductPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'x$quantity',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_currencyFormat.format(price)}₫',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, size: 22, color: AppColors.textSecondary),
    );
  }

  Widget _buildPaymentInfo() {
    final paymentMethod = _order['paymentMethod']?.toString() ?? 'N/A';
    final paymentStatus = _order['paymentStatus']?.toString() ?? 'pending';
    final totalAmount = _order['totalAmount'] ?? 0;
    final createdAt = _order['createdAt']?.toString() ?? '';

    DateTime? date;
    try {
      date = DateTime.parse(createdAt);
    } catch (_) {}

    return _buildSection(
      title: 'Thanh toán',
      icon: Icons.payment_outlined,
      child: Column(
        children: [
          _paymentRow('Phương thức', _formatPaymentMethod(paymentMethod)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              const SizedBox(
                width: 90,
                child: Text('Trạng thái', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
              _buildPaymentStatusBadge(paymentStatus),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 10),
            _paymentRow('Ngày đặt', _dateFormat.format(date)),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Text(
                '${_currencyFormat.format(totalAmount)}₫',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'paid':
        color = AppColors.success;
        label = 'Đã thanh toán';
        break;
      case 'failed':
        color = AppColors.error;
        label = 'Thanh toán lỗi';
        break;
      default:
        color = AppColors.warning;
        label = 'Chưa thanh toán';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Thanh toán khi nhận hàng';
      case 'vnpay':
        return 'VNPay';
      case 'momo':
        return 'MoMo';
      case 'bank_transfer':
        return 'Chuyển khoản';
      default:
        return method;
    }
  }

  Widget _buildNoteSection() {
    return _buildSection(
      title: 'Ghi chú',
      icon: Icons.note_alt_outlined,
      child: Text(
        _order['note'].toString(),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
      ),
    );
  }

  Widget _buildActions() {
    final currentStatus = _order['orderStatus']?.toString() ?? '';
    final isCancelled = currentStatus == 'cancelled';
    final isDelivered = currentStatus == 'delivered';

    if (isCancelled || isDelivered) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Thao tác',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildUpdateStatusButton(currentStatus),
          const SizedBox(height: 10),
          _buildUpdatePaymentButton(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isUpdating ? null : _showCancelOrderDialog,
              icon: const Icon(Icons.cancel, color: AppColors.error),
              label: const Text('Hủy đơn hàng', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateStatusButton(String currentStatus) {
    final currentIdx = _statusFlow.indexOf(currentStatus);
    if (currentIdx < 0 || currentIdx >= _statusFlow.length - 1) {
      return const SizedBox.shrink();
    }
    final nextStatus = _statusFlow[currentIdx + 1];
    final nextLabel = _statusLabels[nextStatus] ?? nextStatus;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : () => _updateOrderStatus(nextStatus),
        icon: Icon(_getStatusIcon(nextStatus)),
        label: Text('Chuyển sang: $nextLabel'),
      ),
    );
  }

  Widget _buildUpdatePaymentButton() {
    final paymentStatus = _order['paymentStatus']?.toString() ?? '';
    if (paymentStatus == 'paid') return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isUpdating ? null : _showPaymentStatusDialog,
        icon: const Icon(Icons.payment),
        label: const Text('Cập nhật thanh toán'),
      ),
    );
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    final confirm = await _showConfirmDialog(
      'Xác nhận',
      'Chuyển trạng thái sang "${_statusLabels[newStatus]}"?',
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      String? paymentStatusUpdate;
      final isCod = _order['paymentMethod']?.toString().toLowerCase() == 'cod';
      if (newStatus == 'delivered' && isCod) {
        paymentStatusUpdate = 'paid';
      }

      await _staffService.updateOrderStatus(
        _order['_id'],
        newStatus,
        paymentStatus: paymentStatusUpdate,
      );

      if (!mounted) return;
      setState(() {
        _order['orderStatus'] = newStatus;
        if (paymentStatusUpdate != null) {
          _order['paymentStatus'] = paymentStatusUpdate;
        }
        _isUpdating = false;
      });
      _showSnackBar('Cập nhật trạng thái thành công', AppColors.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      _showSnackBar('Lỗi: ${e.toString()}', AppColors.error);
    }
  }

  Future<void> _showPaymentStatusDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Cập nhật thanh toán'),
        children: _paymentStatusLabels.entries.map((entry) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, entry.key),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Text(entry.value, style: const TextStyle(fontSize: 15)),
          );
        }).toList(),
      ),
    );
    if (selected == null || selected == _order['paymentStatus']) return;

    setState(() => _isUpdating = true);
    try {
      String? orderStatusUpdate;
      final isOnline = _order['paymentMethod']?.toString().toLowerCase() != 'cod';
      if (selected == 'paid' && _order['orderStatus'] == 'pending_payment' && isOnline) {
        orderStatusUpdate = 'processing';
      }

      await _staffService.updatePaymentStatus(
        _order['_id'],
        selected,
        orderStatus: orderStatusUpdate,
      );

      if (!mounted) return;
      setState(() {
        _order['paymentStatus'] = selected;
        if (orderStatusUpdate != null) {
          _order['orderStatus'] = orderStatusUpdate;
        }
        _isUpdating = false;
      });
      _showSnackBar('Cập nhật thanh toán thành công', AppColors.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      _showSnackBar('Lỗi: ${e.toString()}', AppColors.error);
    }
  }

  Future<void> _showCancelOrderDialog() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập lý do hủy đơn hàng (bắt buộc):'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do tại đây...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final reason = reasonController.text.trim();
    setState(() => _isUpdating = true);
    try {
      await _staffService.updateOrder(
        _order['_id'],
        orderStatus: 'cancelled',
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _order['orderStatus'] = 'cancelled';
        _order['cancellationReason'] = reason;
        _isUpdating = false;
      });
      _showSnackBar('Hủy đơn hàng thành công', AppColors.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      _showSnackBar('Lỗi: ${e.toString()}', AppColors.error);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
