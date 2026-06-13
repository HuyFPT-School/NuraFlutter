import '../config/api_config.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'api_client.dart';

class SupportService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> createConversation(String subject, String firstMessage) async {
    final response = await _api.post(ApiConfig.conversations, data: {
      'subject': subject, 'firstMessage': firstMessage,
    });
    return response.data;
  }

  Future<List<ConversationModel>> getConversations({int page = 1, int limit = 20}) async {
    final response = await _api.get(ApiConfig.conversations, queryParameters: {'page': page, 'limit': limit});
    final data = response.data;
    List list = data is List ? data : (data['conversations'] ?? data['data'] ?? []);
    return list.map((e) => ConversationModel.fromJson(e)).toList();
  }

  Future<ConversationModel> getConversationById(String id) async {
    final response = await _api.get(ApiConfig.conversationById(id));
    final data = response.data;
    final conv = data is Map<String, dynamic> && data.containsKey('conversation') ? data['conversation'] : data;
    return ConversationModel.fromJson(conv);
  }

  Future<List<MessageModel>> getMessages(String conversationId, {int page = 1, int limit = 50}) async {
    final response = await _api.get(
      ApiConfig.conversationMessages(conversationId),
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data;
    List list = data is List ? data : (data['messages'] ?? data['data'] ?? []);
    return list.map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<MessageModel> sendMessage(String conversationId, String content) async {
    final response = await _api.post(
      ApiConfig.conversationMessages(conversationId),
      data: {'content': content},
    );
    final data = response.data;
    final msg = data is Map<String, dynamic> && data.containsKey('message') ? data['message'] : data;
    return MessageModel.fromJson(msg);
  }
}
