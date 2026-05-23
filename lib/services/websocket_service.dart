import 'dart:convert';
import 'dart:async';
import 'package:saifix/helper/custom_print_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'api_service.dart';
import 'notification_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await ApiService.getToken();
    if (token == null) {
      customPrint('WebSocket: No token found, skipping connection.');
      return;
    }

    final baseUrl = ApiService.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final wsUrl = '${baseUrl}ws/notifications/?token=$token';

    try {
      customPrint('WebSocket: Connecting to $wsUrl');

      // نرسل الاتصال بشكل مباشر وبدون Protocols لأننا أوقفنا التحقق من التوكن عند الاتصال
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _isConnected = true;
      _reconnectTimer?.cancel();

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          customPrint('WebSocket: Connection closed.');
          _isConnected = false;
          _scheduleReconnect();
        },
        onError: (error) {
          customPrint('WebSocket: Error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      customPrint('WebSocket: Exception: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) async {
    try {
      customPrint('WebSocket: New message: $message');
      final data = json.decode(message);
      final action = data['action'] ?? data['type'];

      if (action == 'notification') {
        NotificationService.showNotification(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch % 100000,
          title: data['title'] ?? 'إشعار جديد',
          body: data['message'] ?? '',
        );
      } else if (action == 'force_logout') {
        ApiService.logout();
      }
    } catch (e) {
      customPrint('WebSocket: Error parsing message: $e');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(minutes: 5), () {
      customPrint('WebSocket: Attempting to reconnect...');
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
    customPrint('WebSocket: Disconnected manually.');
  }
}

final webSocketService = WebSocketService();
