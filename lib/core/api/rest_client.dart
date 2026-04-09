import 'package:dio/dio.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await localStorage.getIdToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class RestClient {
  final String baseUrl;
  late final Dio _dio;

  RestClient({required this.baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_AuthInterceptor());
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get<T>(path, queryParameters: queryParams);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.delete<T>(path, queryParameters: queryParams);

  Future<Response<T>> postFormData<T>(String path, FormData formData) =>
      _dio.post<T>(path, data: formData);

  Future<Response<T>> patch<T>(String path, {dynamic data, Map<String, dynamic>? queryParams}) =>
      _dio.patch<T>(path, data: data, queryParameters: queryParams);
}

RestClient apiClient = RestClient(
  baseUrl: const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  ),
);
