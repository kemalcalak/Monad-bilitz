import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/config/api_config.dart';

/// Socket.IO service for real-time updates
class WebSocketService {
  IO.Socket? _socket;
  StreamController<WebSocketMessage>? _messageController;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  /// Stream of incoming messages
  Stream<WebSocketMessage> get messageStream {
    _messageController ??= StreamController<WebSocketMessage>.broadcast();
    return _messageController!.stream;
  }

  bool get isConnected => _isConnected;

  /// Connect using Socket.IO. Pass JWT `token` to authenticate.
  void connect({String? token}) {
    if (_isConnected) return;

    final options = IO.OptionBuilder().setTransports(['websocket']).setPath(ApiConfig.socketPath).setExtraHeaders({
      'Accept': 'application/json',
    }).build();

    _socket = IO.io(ApiConfig.realtimeBaseUrl, options);

    // Attach auth if provided (socket_io_client supports sending auth on connect via query or extra headers depending on server)
    if (token != null) {
      _socket!.auth = {'token': token};
    }

    _socket!.on('connect', (_) {
      _isConnected = true;
      _messageController ??= StreamController<WebSocketMessage>.broadcast();
      _messageController?.add(
        WebSocketMessage(type: 'connected', data: {'message': 'connected'}, timestamp: DateTime.now()),
      );
    });

    _socket!.on('disconnect', (_) {
      _isConnected = false;
      _messageController?.addError('disconnected');
      _scheduleReconnect(token: token);
    });

    // Generic handler for known events
    final events = [
      'contract_created',
      'signature_added',
      'contract_finalized',
      'notification',
      'connected',
      'subscribed',
      'error',
    ];

    for (final evt in events) {
      _socket!.on(evt, (payload) {
        final msg = WebSocketMessage(
          type: evt,
          data: payload is Map ? Map<String, dynamic>.from(payload) : {'payload': payload},
          timestamp: DateTime.now(),
        );
        _messageController?.add(msg);
      });
    }

    _socket!.on('connect_error', (err) {
      _isConnected = false;
      _messageController?.addError(err ?? 'connect_error');
      _scheduleReconnect(token: token);
    });
  }

  /// Disconnect socket
  void disconnect() {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Send an emit event
  void emit(String event, Map<String, dynamic> data) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(event, data);
  }

  /// Subscribe to a contract room
  void subscribeToContract(String contractId) {
    emit('subscribe_contract', {'contract_id': contractId});
  }

  /// Unsubscribe from a contract room
  void unsubscribeFromContract(String contractId) {
    emit('unsubscribe_contract', {'contract_id': contractId});
  }

  void _scheduleReconnect({String? token}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(token: token);
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
  }
}

/// WebSocket message model used by the app
class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const WebSocketMessage({required this.type, required this.data, required this.timestamp});
}
