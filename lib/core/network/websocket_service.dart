import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';
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
  final int _maxReconnectAttempts = 15;

  // Offline queue for pending messages when disconnected
  final List<Map<String, dynamic>> _offlineMessageQueue = [];

  final _statusController = StreamController<WebSocketConnectionStatus>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<WebSocketConnectionStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _channel != null;

  WebSocketService({
    String? baseWsUrl,
    required this.storage,
  }) : baseWsUrl = baseWsUrl ?? ApiEndpoints.wsUrl;

  Future<void> connect([String endpoint = '']) async {
    if (_isDisposed) return;

    _statusController.add(WebSocketConnectionStatus.connecting);

    try {
      final token = await storage.getToken();
      final hasQuery = baseWsUrl.contains('?');
      final separator = hasQuery ? '&' : '?';
      final authQuery = token != null ? '${separator}token=$token' : '';
      final cleanEndpoint = endpoint.isEmpty || endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final uri = Uri.parse('$baseWsUrl$cleanEndpoint$authQuery');

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

      // Flush offline messages upon successful connection
      _flushOfflineQueue();
    } catch (e) {
      _statusController.add(WebSocketConnectionStatus.error);
      _scheduleReconnect(endpoint);
    }
  }

  void _onMessageReceived(dynamic rawData) {
    try {
      if (rawData is String) {
        final Map<String, dynamic> decoded = jsonDecode(rawData) as Map<String, dynamic>;
        if (decoded['type'] == 'pong' || decoded['action'] == 'pong') {
          return;
        }
        _messageController.add(decoded);
      }
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      sendMessage({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch});
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
        return;
      } catch (_) {}
    }
    // If not connected, buffer message to offline queue
    _offlineMessageQueue.add(message);
  }

  void _flushOfflineQueue() {
    if (_channel == null || _offlineMessageQueue.isEmpty) return;
    final pending = List<Map<String, dynamic>>.from(_offlineMessageQueue);
    _offlineMessageQueue.clear();

    for (final msg in pending) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (_) {
        _offlineMessageQueue.add(msg);
      }
    }
  }

  // WebRTC Signaling Helper Methods
  void sendCallInvite({
    required String callId,
    required String targetUserId,
    required String callerName,
    String? callerRole,
    String? shipmentId,
  }) {
    sendMessage({
      'type': 'call_invite',
      'action': 'call_invite',
      'call_id': callId,
      'target_user_id': targetUserId,
      'caller_name': callerName,
      'caller_role': callerRole ?? 'shipper',
      'shipment_id': shipmentId,
    });
  }

  void sendCallAccept({required String callId, required String targetUserId}) {
    sendMessage({
      'type': 'call_accept',
      'action': 'call_accept',
      'call_id': callId,
      'target_user_id': targetUserId,
    });
  }

  void sendCallReject({required String callId, required String targetUserId, String reason = 'declined'}) {
    sendMessage({
      'type': 'call_reject',
      'action': 'call_reject',
      'call_id': callId,
      'target_user_id': targetUserId,
      'reason': reason,
    });
  }

  void sendWebrtcOffer({required String callId, required String targetUserId, required Map<String, dynamic> sdp}) {
    sendMessage({
      'type': 'webrtc_offer',
      'action': 'webrtc_offer',
      'call_id': callId,
      'target_user_id': targetUserId,
      'sdp': sdp,
    });
  }

  void sendWebrtcAnswer({required String callId, required String targetUserId, required Map<String, dynamic> sdp}) {
    sendMessage({
      'type': 'webrtc_answer',
      'action': 'webrtc_answer',
      'call_id': callId,
      'target_user_id': targetUserId,
      'sdp': sdp,
    });
  }

  void sendIceCandidate({required String callId, required String targetUserId, required Map<String, dynamic> candidate}) {
    sendMessage({
      'type': 'webrtc_ice_candidate',
      'action': 'webrtc_ice_candidate',
      'call_id': callId,
      'target_user_id': targetUserId,
      'candidate': candidate,
    });
  }

  void sendCallEnd({required String callId, required String targetUserId, int duration = 0}) {
    sendMessage({
      'type': 'call_end',
      'action': 'call_end',
      'call_id': callId,
      'target_user_id': targetUserId,
      'duration': duration,
    });
  }

  // Chat Helpers
  void sendTypingIndicator({required String roomId, required bool isTyping}) {
    sendMessage({
      'type': 'typing',
      'action': 'typing',
      'room_id': roomId,
      'is_typing': isTyping,
    });
  }

  void sendReadReceipt({required String roomId, required String messageId}) {
    sendMessage({
      'type': 'read_receipt',
      'action': 'read_receipt',
      'room_id': roomId,
      'message_id': messageId,
    });
  }

  void sendLocationPin({required String roomId, required double latitude, required double longitude, required String address}) {
    sendMessage({
      'type': 'location_ping',
      'action': 'location_ping',
      'room_id': roomId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
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
