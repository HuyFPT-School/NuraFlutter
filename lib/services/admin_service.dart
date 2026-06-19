import '../config/api_config.dart';
import 'api_client.dart';

class AdminService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getRevenueSummary() async {
    final response = await _client.get(ApiConfig.revenueSummary);
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<Map<String, dynamic>> getOrdersStats() async {
    final response = await _client.get(ApiConfig.ordersStats);
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<List<dynamic>> getTopProducts({int limit = 5}) async {
    final response = await _client.get(
      ApiConfig.topProducts,
      queryParameters: {'limit': limit},
    );
    if (response.data is Map && response.data['data'] != null) {
      return response.data['data'] as List<dynamic>;
    }
    if (response.data is List) return response.data;
    return [];
  }

  Future<List<dynamic>> getAllUsers({
    String? search,
    String? role,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(ApiConfig.allUsers);
    if (response.data is Map && response.data['data'] != null) {
      List<dynamic> users = response.data['data'] as List<dynamic>;
      
      // Filter locally
      if (role != null && role.isNotEmpty) {
        users = users.where((u) => u['role'] == role).toList();
      }
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        users = users.where((u) {
          final fullname = (u['fullname'] as String?)?.toLowerCase() ?? '';
          final email = (u['email'] as String?)?.toLowerCase() ?? '';
          final phone = (u['phone'] as String?)?.toLowerCase() ?? '';
          return fullname.contains(query) || email.contains(query) || phone.contains(query);
        }).toList();
      }
      
      // Paginate locally
      final startIndex = (page - 1) * limit;
      if (startIndex >= users.length) return [];
      final endIndex = startIndex + limit;
      return users.sublist(startIndex, endIndex > users.length ? users.length : endIndex);
    }
    return [];
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    await _client.post(ApiConfig.createUserEndpoint, data: data);
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _client.patch(ApiConfig.updateUserEndpoint(id), data: data);
  }

  Future<void> deleteUser(String id) async {
    await _client.dio.delete(ApiConfig.deleteUserEndpoint(id));
  }
}
