import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/staff_service.dart';
import 'staff_home_screen.dart';
import 'staff_order_detail_screen.dart';

import '../../config/routes.dart';

class StaffDashboardTab extends StatefulWidget {
  const StaffDashboardTab({super.key});
  @override
  State<StaffDashboardTab> createState() => _StaffDashboardTabState();
}

class _StaffDashboardTabState extends State<StaffDashboardTab> {
  final _staffService = StaffService();
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<dynamic> _lowStockProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _staffService.getDashboardStats(),
        _staffService.getLowStockProducts(10),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _lowStockProducts = results[1] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.pushNamed(context, AppRoutes.staffCreateProduct);
          if (created == true) {
            _loadData();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Tạo sản phẩm mới',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState();
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildPendingOrdersSection(),
          const SizedBox(height: 24),
          _buildLowStockSection(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      _StatItem('Chờ xác nhận', _stats['pendingOrders'] ?? 0, 'đơn hàng cần xử lý', Icons.access_time_rounded, AppColors.warning),
      _StatItem('Đang xử lý', _stats['confirmedOrders'] ?? 0, 'đơn đã xác nhận', Icons.check_circle_outline_rounded, Colors.blue),
      _StatItem('Đang giao', _stats['shippingOrders'] ?? 0, 'đơn đang vận chuyển', Icons.local_shipping_outlined, Colors.purple),
    ];

    return Row(
      children: [
        Expanded(child: _buildStatCard(items[0])),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(items[1])),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(items[2])),
      ],
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16, color: item.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${item.count}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.desc,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrdersSection() {
    final pendingList = _stats['pendingOrdersList'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Đơn hàng chờ xử lý',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                final homeState = context.findAncestorStateOfType<StaffHomeScreenState>();
                if (homeState != null) {
                  homeState.setIndex(1);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Xem tất cả', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pendingList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: cardDecoration,
            child: const Center(
              child: Text(
                'Không có đơn hàng chờ xử lý',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...List.generate(pendingList.length, (index) {
            final order = pendingList[index] as Map<String, dynamic>;
            return _buildPendingOrderCard(order);
          }),
      ],
    );
  }

  Widget _buildPendingOrderCard(Map<String, dynamic> order) {
    final orderId = order['_id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;
    final customerName = order['customer']?['fullname'] ?? 'Khách hàng';
    final total = order['totalAmount'] ?? 0;
    final createdAt = order['createdAt']?.toString() ?? '';

    DateTime? date;
    try {
      date = DateTime.parse(createdAt);
    } catch (_) {}

    final dateStr = date != null ? DateFormat('HH:mm dd thg M, yyyy').format(date) : '';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StaffOrderDetailScreen(order: order)),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORD-$shortId'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '${_currencyFormat.format(total)} đ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text(
              'Sản phẩm sắp hết hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_lowStockProducts.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lowStockProducts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: cardDecoration,
            child: const Column(
              children: [
                Icon(Icons.check_circle, size: 40, color: AppColors.success),
                SizedBox(height: 8),
                Text(
                  'Tất cả sản phẩm đều đủ hàng',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ...List.generate(_lowStockProducts.length, (index) {
            final product = _lowStockProducts[index];
            return _buildLowStockItem(product);
          }),
      ],
    );
  }

  Widget _buildLowStockItem(Map<String, dynamic> product) {
    final quantity = product['quantity'] ?? 0;
    final isUrgent = quantity <= 3;
    final imageUrlList = product['imageUrl'];
    final image = (imageUrlList is List && imageUrlList.isNotEmpty) ? imageUrlList[0] : imageUrlList;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration,
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
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Không rõ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currencyFormat.format(product['price'] ?? 0)}₫',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Còn $quantity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isUrgent ? AppColors.error : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, size: 24, color: AppColors.textSecondary),
    );
  }
}

class _StatItem {
  final String label;
  final int count;
  final String desc;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.count, this.desc, this.icon, this.color);
}
