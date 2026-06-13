import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(ApiConfig.login, data: {'email': email, 'password': password});
    return response.data;
  }

  Future<Map<String, dynamic>> register(String email, String password, String fullname) async {
    final response = await _api.post(ApiConfig.register, data: {
      'email': email, 'password': password, 'fullname': fullname,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    final response = await _api.post(ApiConfig.verifyEmail, data: {'email': email, 'otp': otp});
    return response.data;
  }

  Future<void> logout() async {
    await _api.post(ApiConfig.logout);
  }

  Future<void> forgetPassword(String email) async {
    await _api.post(ApiConfig.forgetPassword, data: {'email': email});
  }

  Future<void> resetPassword(String otp, String newPassword) async {
    await _api.post(ApiConfig.resetPassword, data: {'otp': otp, 'newPassword': newPassword});
  }

  Future<void> sendResetOtp(String email) async {
    await _api.post(ApiConfig.sendResetOtp, data: {'email': email});
  }
}
