import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/config/api_config.dart';

/// WebSocket service for real-time updates
class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<WebSocketMessage>? _messageController;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  /// Stream of incoming messages
  Stream<WebSocketMessage> get messageStream {
    _messageController ??= StreamController<WebSocketMessage>.broadcast();
    return _messageController!.stream;
  }
  
  /// Connection status
  bool get isConnected => _isConnected;
  
  /// Connect to WebSocket server
  Future<void> connect({String? token}) async {
    if (_isConnected) return;
    
    try {
      final uri = Uri.parse(
        token != null 
          ? '${ApiConfig.wsUrl}?token=$token' 
          : ApiConfig.wsUrl
      );
      
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      
      _messageController ??= StreamController<WebSocketMessage>.broadcast();
      
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _startPingTimer();
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect(token: token);
    }
  }
  
  /// Disconnect from WebSocket server
  void disconnect() {
    _cancelTimers();
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }
  
  /// Send a message
  void send(String type, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;
    
    final message = jsonEncode({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _channel!.sink.add(message);
  }
  
  /// Subscribe to contract updates
  void subscribeToContracts(List<String> contractIds) {
    send('subscribe_contracts', {'contract_ids': contractIds});
  }
  
  /// Subscribe to signature requests
  void subscribeToSignatures(String userId) {
    send('subscribe_signatures', {'user_id': userId});
  }
  
  /// Subscribe to hierarchy updates
  void subscribeToHierarchy() {
    send('subscribe_hierarchy', {});
  }
  
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final wsMessage = WebSocketMessage.fromJson(data);
      _messageController?.add(wsMessage);
    } catch (e) {
      // Invalid message format
    }
  }
  
  void _onError(dynamic error) {
    _isConnected = false;
    _messageController?.addError(error);
  }
  
  void _onDone() {
    _isConnected = false;
    _scheduleReconnect();
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        send('ping', {});
      }
    });
  }
  
  void _scheduleReconnect({String? token}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(token: token);
    });
  }
  
  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
  }
  
  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
  }
}

/// WebSocket message model
class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  const WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
  });
  
  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// WebSocket message types
class WsMessageType {
  WsMessageType._();
  
  static const String contractCreated = 'contract_created';
  static const String contractUpdated = 'contract_updated';
  static const String contractApproved = 'contract_approved';
  static const String contractRejected = 'contract_rejected';
  static const String signatureRequested = 'signature_requested';
  static const String signatureProvided = 'signature_provided';
  static const String memberAdded = 'member_added';
  static const String memberUpdated = 'member_updated';
  static const String ping = 'ping';
  static const String pong = 'pong';
}
