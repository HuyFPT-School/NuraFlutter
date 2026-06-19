import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/staff_service.dart';
import 'staff_order_detail_screen.dart';

class StaffOrdersTab extends StatefulWidget {
  const StaffOrdersTab({super.key});
  @override
  State<StaffOrdersTab> createState() => _StaffOrdersTabState();
}

class _StaffOrdersTabState extends State<StaffOrdersTab> with SingleTickerProviderStateMixin {
  final _staffService = StaffService();
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  late TabController _tabController;

  final _statusFilters = [null, 'pending_payment', 'processing', 'shipped', 'delivered', 'cancelled'];
  final _tabLabels = ['Tất cả', 'Chờ thanh toán', 'Chờ xử lý', 'Đang giao', 'Đã giao', 'Đã hủy'];

  List<dynamic> _orders = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _currentPage = 1;
    _orders.clear();
    _loadOrders();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _staffService.getAllOrders(
        status: _statusFilters[_tabController.index],
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: 1,
        limit: 15,
      );
      if (!mounted) return;
      setState(() {
        _orders = result['orders'] as List<dynamic>? ?? [];
        _totalPages = result['totalPages'] as int? ?? 1;
        _currentPage = 1;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _staffService.getAllOrders(
        status: _statusFilters[_tabController.index],
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _currentPage + 1,
        limit: 15,
      );
      if (!mounted) return;
      setState(() {
        _orders.addAll(result['orders'] as List<dynamic>? ?? []);
        _currentPage = result['currentPage'] as int? ?? _currentPage + 1;
        _totalPages = result['totalPages'] as int? ?? _totalPages;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearch(String _) {
    _currentPage = 1;
    _orders.clear();
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabAlignment: TabAlignment.start,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onSubmitted: _onSearch,
        decoration: InputDecoration(
          hintText: 'Tìm theo SĐT hoặc địa chỉ...',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loadOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Không có đơn hàng', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadOrders,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['_id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;
    final customerName = order['customer']?['fullname'] ?? 'Khách hàng';
    final total = order['totalAmount'] ?? 0;
    final status = order['orderStatus']?.toString() ?? '';
    final paymentStatus = order['paymentStatus']?.toString() ?? '';
    final createdAt = order['createdAt']?.toString() ?? '';

    DateTime? date;
    try {
      date = DateTime.parse(createdAt);
    } catch (_) {}

    return GestureDetector(
      onTap: () => _navigateToDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$shortId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const Spacer(),
                if (date != null)
                  Text(
                    _dateFormat.format(date),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              customerName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${_currencyFormat.format(total)}₫',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                _buildPaymentBadge(paymentStatus),
                const SizedBox(width: 6),
                _buildStatusBadge(status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: config.color),
      ),
    );
  }

  Widget _buildPaymentBadge(String paymentStatus) {
    final config = _getPaymentConfig(paymentStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: config.color),
      ),
    );
  }

  _BadgeConfig _getStatusConfig(String status) {
    switch (status) {
      case 'pending_payment':
        return _BadgeConfig('Chờ thanh toán', Colors.orange);
      case 'processing':
        return _BadgeConfig('Chờ xử lý', AppColors.warning);
      case 'shipped':
        return _BadgeConfig('Đang giao', Colors.blue);
      case 'delivered':
        return _BadgeConfig('Đã giao', AppColors.success);
      case 'cancelled':
        return _BadgeConfig('Đã hủy', AppColors.error);
      default:
        return _BadgeConfig(status, AppColors.textSecondary);
    }
  }

  _BadgeConfig _getPaymentConfig(String paymentStatus) {
    switch (paymentStatus) {
      case 'pending':
        return _BadgeConfig('Chưa TT', AppColors.warning);
      case 'paid':
        return _BadgeConfig('Đã TT', AppColors.success);
      case 'failed':
        return _BadgeConfig('TT lỗi', AppColors.error);
      default:
        return _BadgeConfig(paymentStatus, AppColors.textSecondary);
    }
  }

  Future<void> _navigateToDetail(Map<String, dynamic> order) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StaffOrderDetailScreen(order: order)),
    );
    if (result == true) {
      _loadOrders();
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color color;
  const _BadgeConfig(this.label, this.color);
}
