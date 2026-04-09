import 'package:flutter_test/flutter_test.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';

void main() {
  test('RestClient builds correct base URL', () {
    final client = RestClient(baseUrl: 'http://localhost:8000');
    expect(client.baseUrl, equals('http://localhost:8000'));
  });
}
