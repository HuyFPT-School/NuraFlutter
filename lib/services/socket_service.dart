import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    _socket = io.io(ApiConfig.baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableAutoConnect()
      .enableReconnection()
      .build(),
    );

    _socket!.onConnect((_) {});
    _socket!.onDisconnect((_) {});
    _socket!.onConnectError((data) {});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void joinConversation(String conversationId) {
    _socket?.emit('support:join_conversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('support:leave_conversation', conversationId);
  }

  void onNewMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('support:new_message', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void onStatusChanged(Function(Map<String, dynamic>) callback) {
    _socket?.on('support:status_changed', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void offNewMessage() {
    _socket?.off('support:new_message');
  }

  void dispose() {
    _socket?.clearListeners();
    disconnect();
  }
}
