import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/api_client.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _service.getMyOrders(status: status);
    } on DioException catch (e) {
      _error = ApiClient.getErrorMessage(e);
    } catch (e) {
      _error = 'Không thể tải đơn hàng.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOrderDetail(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedOrder = await _service.getOrderById(id);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> cancelOrder(String id, String reason) async {
    try {
      await _service.cancelOrder(id, reason);
      await loadMyOrders();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmDelivery(String id) async {
    try {
      await _service.confirmDelivery(id);
      await loadMyOrders();
      return true;
    } catch (_) {
      return false;
    }
  }
}
