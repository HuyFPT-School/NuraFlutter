import '../config/api_config.dart';
import 'api_client.dart';

class CheckoutService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> cartItems,
    required String paymentMethod,
    String? voucherCode,
    required String shippingAddress,
    required String phone,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'cartItems': cartItems,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
      'phone': phone,
    };
    if (voucherCode != null && voucherCode.isNotEmpty) body['voucherUsed'] = voucherCode;
    if (note != null && note.isNotEmpty) body['note'] = note;

    final response = await _api.post(ApiConfig.checkout, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> validateVoucher(String code, double orderTotal) async {
    final response = await _api.post(ApiConfig.validateVoucher, data: {
      'code': code, 'orderTotal': orderTotal,
    });
    return response.data;
  }
}
