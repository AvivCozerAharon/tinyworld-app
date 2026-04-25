import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef TokenProvider = Future<String> Function();

class MapWsService {
  final String sessionId;
  final TokenProvider tokenProvider;
  final String wsBaseUrl;

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnects = 5;
  static const _baseDelay = Duration(seconds: 3);
  bool _disposed = false;

  MapWsService({
    required this.sessionId,
    required this.tokenProvider,
    required this.wsBaseUrl,
  });

  Stream<Map<String, dynamic>> get events => _controller.stream;

  Future<void> connect() async {
    if (_disposed) return;
    final token = await tokenProvider();
    final uri = Uri.parse('$wsBaseUrl/ws/stream/$sessionId');
    _channel = IOWebSocketChannel.connect(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    _channel!.stream.cast<String>().listen(
      (raw) {
        final event = jsonDecode(raw) as Map<String, dynamic>;
        if (event['event'] == 'ping') {
          _channel?.sink.add(jsonEncode({'event': 'pong'}));
          return;
        }
        if (!_controller.isClosed) _controller.add(event);
      },
      onDone: _onDisconnect,
      onError: (_) => _onDisconnect(),
    );
    _reconnectAttempts = 0;
  }

  void _onDisconnect() {
    if (_disposed || _reconnectAttempts >= _maxReconnects) {
      if (!_disposed && !_controller.isClosed) _controller.close();
      return;
    }
    final delay = _baseDelay * (1 << _reconnectAttempts);
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () async {
      try {
        await connect();
      } catch (_) {
        _onDisconnect();
      }
    });
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    if (!_controller.isClosed) _controller.close();
  }
}
