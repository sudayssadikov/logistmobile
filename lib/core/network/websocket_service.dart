import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/local_storage_service.dart';

enum WebSocketConnectionStatus { connecting, connected, disconnected, error }

class WebSocketService {
  final String baseWsUrl;
  final ILocalStorageService storage;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;

  final _statusController = StreamController<WebSocketConnectionStatus>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<WebSocketConnectionStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  WebSocketService({
    this.baseWsUrl = 'ws://localhost:8000/api/v1/ws',
    required this.storage,
  });

  Future<void> connect(String endpoint) async {
    if (_isDisposed) return;

    _statusController.add(WebSocketConnectionStatus.connecting);

    try {
      final token = await storage.getToken();
      final uri = Uri.parse('$baseWsUrl$endpoint${token != null ? "?token=$token" : ""}');

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (dynamic data) {
          _onMessageReceived(data);
        },
        onDone: () {
          _onDisconnected(endpoint);
        },
        onError: (dynamic error) {
          _statusController.add(WebSocketConnectionStatus.error);
          _onDisconnected(endpoint);
        },
        cancelOnError: true,
      );

      _statusController.add(WebSocketConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
    } catch (e) {
      _statusController.add(WebSocketConnectionStatus.error);
      _scheduleReconnect(endpoint);
    }
  }

  void _onMessageReceived(dynamic rawData) {
    try {
      if (rawData is String) {
        final Map<String, dynamic> decoded = jsonDecode(rawData) as Map<String, dynamic>;
        if (decoded['type'] == 'pong') {
          // Heartbeat response
          return;
        }
        _messageController.add(decoded);
      }
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      sendMessage({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch});
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    try {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode(message));
      }
    } catch (_) {}
  }

  void _onDisconnected(String endpoint) {
    _statusController.add(WebSocketConnectionStatus.disconnected);
    _heartbeatTimer?.cancel();
    _scheduleReconnect(endpoint);
  }

  void _scheduleReconnect(String endpoint) {
    if (_isDisposed || _reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectTimer?.cancel();
    final delaySeconds = (_reconnectAttempts + 1) * 2;
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect(endpoint);
    });
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _statusController.add(WebSocketConnectionStatus.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _statusController.close();
    _messageController.close();
  }
}
