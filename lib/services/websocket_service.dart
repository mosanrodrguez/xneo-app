import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static StreamController<Map<String, dynamic>>? _messageController;
  static StreamController<Map<String, dynamic>>? _notificationController;
  static String? _token;
  static bool _isConnected = false;
  static Timer? _reconnectTimer;

  static Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;
  static Stream<Map<String, dynamic>>? get notificationStream => _notificationController?.stream;
  static bool get isConnected => _isConnected;

  static Future<void> connect(String token) async {
    _token = token;
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    _notificationController = StreamController<Map<String, dynamic>>.broadcast();
    
    _doConnect();
  }

  static void _doConnect() {
    try {
      final wsUrl = 'wss://xneo-web.onrender.com/ws?token=$_token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (data) {
          final message = json.decode(data);
          _handleMessage(message);
        },
        onDone: () {
          _isConnected = false;
          _reconnect();
        },
        onError: (error) {
          _isConnected = false;
          _reconnect();
        },
      );
      
      _isConnected = true;
      print('✅ WebSocket conectado');
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
      _reconnect();
    }
  }

  static void _reconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('🔄 Reconectando WebSocket...');
      _doConnect();
    });
  }

  static void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    
    switch (type) {
      case 'new_message':
        _messageController?.add(message);
        break;
      case 'message_status':
        _messageController?.add(message);
        break;
      case 'incoming_call':
        _notificationController?.add(message);
        break;
      case 'call_accepted':
        _notificationController?.add(message);
        break;
      case 'call_rejected':
        _notificationController?.add(message);
        break;
      case 'call_ended':
        _notificationController?.add(message);
        break;
      case 'user_typing':
        _messageController?.add(message);
        break;
      case 'user_online':
        _messageController?.add(message);
        break;
      case 'new_video':
        _notificationController?.add(message);
        break;
      default:
        print('Mensaje desconocido: $type');
    }
  }

  static void sendMessage(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(json.encode(data));
    }
  }

  static void sendTyping(String chatId, String userId) {
    sendMessage({
      'type': 'typing',
      'chatId': chatId,
      'userId': userId,
    });
  }

  static void sendCallSignal(String userId, String type, Map<String, dynamic>? data) {
    sendMessage({
      'type': 'call_signal',
      'to': userId,
      'signalType': type,
      'data': data,
    });
  }

  static void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController?.close();
    _notificationController?.close();
    _isConnected = false;
  }
}
