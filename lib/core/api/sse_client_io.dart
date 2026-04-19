import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';

class SSEEvent {
  final String event;
  final Map<String, dynamic>? data;
  final String? rawData;

  const SSEEvent({required this.event, this.data, this.rawData});
}

class SSEClient {
  final String baseUrl;
  final Dio _dio;

  SSEClient({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(minutes: 10),
        ));

  Stream<SSEEvent> post(String path, {Map<String, dynamic>? data}) async* {
    final token = await localStorage.getIdToken();
    final response = await _dio.post<ResponseBody>(
      path,
      data: data,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null) return;

    String buffer = '';
    String? eventType;

    await for (final chunk in body.stream) {
      buffer += utf8.decode(chunk);

      while (buffer.contains('\n')) {
        final idx = buffer.indexOf('\n');
        final line = buffer.substring(0, idx).trimRight();
        buffer = buffer.substring(idx + 1);

        if (line.startsWith('event: ')) {
          eventType = line.substring(7).trim();
        } else if (line.startsWith('data: ')) {
          final payload = line.substring(6);
          Map<String, dynamic>? jsonData;
          try {
            jsonData = jsonDecode(payload) as Map<String, dynamic>;
          } catch (_) {}
          yield SSEEvent(
            event: eventType ?? 'message',
            data: jsonData,
            rawData: jsonData == null ? payload : null,
          );
          eventType = null;
        }
      }
    }
  }
}

final sseClient = SSEClient(
  baseUrl: const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  ),
);
