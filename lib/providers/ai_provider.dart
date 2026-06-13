import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_message_model.dart';
import '../services/ai_service.dart';

class AiProvider extends ChangeNotifier {
  final AiService _service = AiService();
  static const String _sessionKey = 'ai_session_id';

  List<AiMessageModel> _messages = [];
  String? _sessionId;
  bool _isLoading = false;
  String? _error;

  List<AiMessageModel> get messages => _messages;
  String? get sessionId => _sessionId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString(_sessionKey);
    if (_sessionId != null) {
      await loadHistory(_sessionId!);
    }
  }

  Future<void> loadHistory(String sessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getChatHistory(sessId);
      if (data['success'] == true && data['data'] != null) {
        final messagesJson = data['data']['messages'] as List?;
        if (messagesJson != null) {
          _messages = messagesJson
              .map((m) => AiMessageModel.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          _sessionId = sessId;
        }
      }
    } catch (_) {
      // If history is not found (e.g. deleted on server), clear session
      _sessionId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      _messages = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message locally for immediate UI update
    final userMsg = AiMessageModel(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.chat(text, _sessionId);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final reply = data['reply'] ?? '';
        final newSessId = data['sessionId']?.toString();
        final listSuggest = data['suggestedProducts'] ?? [];

        final assistantMsg = AiMessageModel.fromJson({
          'role': 'assistant',
          'content': reply,
          'timestamp': DateTime.now().toIso8601String(),
          'suggestedProducts': listSuggest,
        });
        _messages.add(assistantMsg);

        if (_sessionId != newSessId && newSessId != null) {
          _sessionId = newSessId;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, _sessionId!);
        }
      }
    } catch (e, stack) {
      print('Error in sendMessage: $e');
      print(stack);
      _error = 'Đã xảy ra lỗi khi trao đổi với AI.';
      // Remove the unsent message or show error in message list if preferred
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    if (_sessionId != null) {
      try {
        await _service.deleteChatHistory(_sessionId!);
      } catch (_) {}
    }
    _messages = [];
    _sessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }
}
