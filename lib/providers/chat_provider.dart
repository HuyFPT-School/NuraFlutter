import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/support_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final SupportService _service = SupportService();
  final SocketService _socket = SocketService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  ConversationModel? _activeConversation;
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  ConversationModel? get activeConversation => _activeConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      _conversations = await _service.getConversations();
    } catch (_) {
      _error = 'Không thể tải cuộc hội thoại.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createConversation(String subject, String message) async {
    try {
      final data = await _service.createConversation(subject, message);
      final conv = data['conversation'] ?? data;
      final newConv = ConversationModel.fromJson(conv is Map<String, dynamic> ? conv : {});
      _conversations.insert(0, newConv);
      notifyListeners();
      return newConv.id;
    } catch (_) {
      _error = 'Không thể tạo cuộc hội thoại.';
      notifyListeners();
      return null;
    }
  }

  Future<void> openConversation(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _activeConversation = await _service.getConversationById(id);
      _messages = await _service.getMessages(id);
      _messages = _messages.reversed.toList();
      _socket.joinConversation(id);
      _socket.onNewMessage(_handleNewMessage);
    } catch (_) {
      _error = 'Không thể tải tin nhắn.';
    }
    _isLoading = false;
    notifyListeners();
  }

  void closeConversation() {
    if (_activeConversation != null) {
      _socket.leaveConversation(_activeConversation!.id);
      _socket.offNewMessage();
    }
    _activeConversation = null;
    _messages = [];
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (_activeConversation == null) return;
    try {
      final msg = await _service.sendMessage(_activeConversation!.id, content);
      _messages.add(msg);
      notifyListeners();
    } catch (_) {}
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final msg = MessageModel.fromJson(data);
      if (_activeConversation != null && msg.conversation == _activeConversation!.id) {
        _messages.add(msg);
        notifyListeners();
      }
    } catch (_) {}
  }

  void connectSocket(String token) {
    _socket.connect(token);
  }

  void disconnectSocket() {
    _socket.dispose();
  }
}
