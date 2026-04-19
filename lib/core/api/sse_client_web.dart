import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:tinyworld_app/core/storage/local_storage.dart';

class SSEEvent {
  final String event;
  final Map<String, dynamic>? data;
  final String? rawData;

  const SSEEvent({required this.event, this.data, this.rawData});
}

class SSEClient {
  final String baseUrl;

  SSEClient({required this.baseUrl});

  Stream<SSEEvent> post(String path, {Map<String, dynamic>? data}) async* {
    final token = await localStorage.getIdToken();
    final controller = StreamController<SSEEvent>();
    final xhr = html.HttpRequest();
    xhr.open('POST', '$baseUrl$path', async: true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('Accept', 'text/event-stream');
    if (token != null) {
      xhr.setRequestHeader('Authorization', 'Bearer $token');
    }

    int processed = 0;
    String? eventType;
    String lineBuffer = '';

    void parseLine(String line) {
      line = line.trimRight();
      if (line.startsWith('event: ')) {
        eventType = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        final payload = line.substring(6);
        Map<String, dynamic>? jsonData;
        try {
          jsonData = jsonDecode(payload) as Map<String, dynamic>;
        } catch (_) {}
        controller.add(SSEEvent(
          event: eventType ?? 'message',
          data: jsonData,
          rawData: jsonData == null ? payload : null,
        ));
        eventType = null;
      }
    }

    void processChunk(String chunk) {
      lineBuffer += chunk;
      while (lineBuffer.contains('\n')) {
        final idx = lineBuffer.indexOf('\n');
        final line = lineBuffer.substring(0, idx);
        lineBuffer = lineBuffer.substring(idx + 1);
        parseLine(line);
      }
    }

    xhr.onProgress.listen((_) {
      final text = xhr.responseText ?? '';
      if (text.length > processed) {
        processChunk(text.substring(processed));
        processed = text.length;
      }
    });

    xhr.onLoad.listen((_) => controller.close());
    xhr.onError.listen((_) {
      controller.addError(Exception('XHR error'));
      controller.close();
    });

    xhr.send(data != null ? jsonEncode(data) : null);

    yield* controller.stream;
  }
}

final sseClient = SSEClient(
  baseUrl: const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  ),
);
