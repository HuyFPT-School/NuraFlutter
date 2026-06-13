import '../config/api_config.dart';
import '../models/order_model.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _api = ApiClient();

  Future<List<OrderModel>> getMyOrders({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final response = await _api.get(ApiConfig.myOrders, queryParameters: params);
    final data = response.data;
    List list = data is List ? data : (data['orders'] ?? data['data'] ?? []);
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<OrderModel> getOrderById(String id) async {
    final response = await _api.get(ApiConfig.orderById(id));
    final data = response.data;
    final order = data is Map<String, dynamic> && data.containsKey('order') ? data['order'] : data;
    return OrderModel.fromJson(order);
  }

  Future<void> cancelOrder(String id, String reason) async {
    await _api.patch(ApiConfig.cancelOrder(id), data: {'reason': reason});
  }

  Future<void> confirmDelivery(String id) async {
    await _api.patch(ApiConfig.confirmDelivery(id));
  }

  Future<Map<String, dynamic>> retryPayment(String id) async {
    final response = await _api.post(ApiConfig.retryPayment(id));
    return response.data;
  }
}
