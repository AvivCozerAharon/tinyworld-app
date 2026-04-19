import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SimulationStream {
  final String sessionId;
  final String token;
  final String baseWsUrl;
  WebSocketChannel? _channel;

  SimulationStream({
    required this.sessionId,
    required this.token,
    required this.baseWsUrl,
  });

  Stream<Map<String, dynamic>> connect() {
    final uri = Uri.parse('$baseWsUrl/ws/stream/$sessionId?token=${Uri.encodeComponent(token)}');
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream
        .cast<String>()
        .map((raw) => jsonDecode(raw) as Map<String, dynamic>);
  }

  void dispose() {
    _channel?.sink.close();
  }
}

class ChatStream {
  final String simId;
  final String token;
  final String baseWsUrl;
  WebSocketChannel? _channel;

  ChatStream({
    required this.simId,
    required this.token,
    required this.baseWsUrl,
  });

  Stream<Map<String, dynamic>> connect() {
    final uri = Uri.parse('$baseWsUrl/ws/chat/$simId?token=${Uri.encodeComponent(token)}');
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream
        .cast<String>()
        .map((raw) => jsonDecode(raw) as Map<String, dynamic>);
  }

  void send(String text) {
    _channel?.sink.add(jsonEncode({'text': text}));
  }

  void dispose() {
    _channel?.sink.close();
  }
}
