import '../config/api_config.dart';
import 'api_client.dart';

class StaffService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _client.get(ApiConfig.allOrders);
    if (response.data is Map && response.data['orders'] != null) {
      final orders = response.data['orders'] as List<dynamic>;
      int pending = 0;
      int confirmed = 0;
      int shipping = 0;
      int delivered = 0;
      int cancelled = 0;
      int totalRevenue = 0;

      for (var o in orders) {
        final status = o['orderStatus'] as String?;
        final paymentStatus = o['paymentStatus'] as String?;
        final totalAmount = o['totalAmount'] as num?;

        if (status == 'processing') {
          if (paymentStatus == 'pending') {
            pending++;
          } else if (paymentStatus == 'paid') {
            confirmed++;
          }
        } else if (status == 'shipped') {
          shipping++;
        } else if (status == 'delivered') {
          delivered++;
        } else if (status == 'cancelled') {
          cancelled++;
        }

        if (paymentStatus == 'paid' && totalAmount != null) {
          totalRevenue += totalAmount.toInt();
        }
      }

      final pendingOrdersList = orders
          .where((o) =>
              o['orderStatus'] == 'processing' ||
              o['orderStatus'] == 'pending_payment')
          .take(5)
          .toList();

      return {
        'pendingOrders': pending,
        'confirmedOrders': confirmed,
        'shippingOrders': shipping,
        'deliveredOrders': delivered,
        'cancelledOrders': cancelled,
        'totalRevenue': totalRevenue,
        'pendingOrdersList': pendingOrdersList,
      };
    }
    return {};
  }

  Future<List<dynamic>> getLowStockProducts(int threshold) async {
    final response = await _client.get('/api/product');
    if (response.data is Map && response.data['data'] != null) {
      final list = response.data['data'] as List<dynamic>;
      return list.where((p) {
        final quantity = p['quantity'] ?? 0;
        return quantity <= threshold;
      }).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getAllOrders({
    String? status,
    String? paymentStatus,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      params['paymentStatus'] = paymentStatus;
    }
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _client.get(
      ApiConfig.allOrders,
      queryParameters: params,
    );

    if (response.data is Map && response.data['orders'] != null) {
      final allOrders = response.data['orders'] as List<dynamic>;
      final total = allOrders.length;
      final totalPages = (total / limit).ceil();

      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final ordersPage = startIndex >= total
          ? []
          : allOrders.sublist(startIndex, endIndex > total ? total : endIndex);

      return {
        'orders': ordersPage,
        'totalPages': totalPages,
        'currentPage': page,
        'total': total,
      };
    }
    return {
      'orders': [],
      'totalPages': 0,
      'currentPage': page,
      'total': 0,
    };
  }

  Future<void> updateOrder(
    String orderId, {
    String? orderStatus,
    String? paymentStatus,
    String? reason,
  }) async {
    final data = <String, dynamic>{};
    if (orderStatus != null) data['orderStatus'] = orderStatus;
    if (paymentStatus != null) data['paymentStatus'] = paymentStatus;
    if (reason != null) data['reason'] = reason;

    await _client.patch(
      ApiConfig.updateOrderStatus(orderId),
      data: data,
    );
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? paymentStatus}) async {
    await updateOrder(orderId, orderStatus: status, paymentStatus: paymentStatus);
  }

  Future<void> updatePaymentStatus(String orderId, String status, {String? orderStatus}) async {
    await updateOrder(orderId, paymentStatus: status, orderStatus: orderStatus);
  }
}
