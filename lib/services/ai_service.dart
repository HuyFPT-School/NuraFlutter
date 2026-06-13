import 'api_client.dart';

class AiService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> chat(String message, String? sessionId) async {
    final body = <String, dynamic>{'message': message};
    if (sessionId != null && sessionId.isNotEmpty) {
      body['sessionId'] = sessionId;
    }

    final response = await _api.post('/api/ai/chat', data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> getChatHistory(String sessionId) async {
    final response = await _api.get('/api/ai/history/$sessionId');
    return response.data;
  }

  Future<List<dynamic>> getUserChatHistories(String userId) async {
    final response = await _api.get('/api/ai/history/user/$userId');
    if (response.data is Map && response.data['data'] != null) {
      return response.data['data'] as List<dynamic>;
    }
    return [];
  }

  Future<void> deleteChatHistory(String sessionId) async {
    await _api.delete('/api/ai/history/$sessionId');
  }
}
