import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _retryWithFreshToken(err, handler);
      return;
    }
    handler.next(err);
  }

  Future<void> _retryWithFreshToken(DioException err, ErrorInterceptorHandler handler) async {
    try {
      try { FirebaseAuth.instance.app; } catch (_) { throw Exception('no firebase'); }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newToken = await user.getIdToken(true);
        if (newToken != null) {
          await localStorage.saveIdToken(newToken);
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final dio = Dio(BaseOptions(
            baseUrl: opts.baseUrl,
            connectTimeout: opts.connectTimeout,
            receiveTimeout: opts.receiveTimeout,
            validateStatus: (s) => s != null && s < 500,
          ));
          final resp = await dio.fetch(opts);
          if (resp.statusCode != 401) {
            return handler.resolve(resp);
          }
        }
      }
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    await localStorage.clearAll();
    handler.next(err);
  }
}

typedef ApiErrorCallback = void Function(String message);

class ErrorInterceptor extends Interceptor {
  static ApiErrorCallback? onApiError;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final msg = _userFriendlyMessage(err);
    if (onApiError != null) {
      onApiError!(msg);
    }
    handler.next(err);
  }

  String _userFriendlyMessage(DioException err) {
    final status = err.response?.statusCode;
    if (status == null || status == 0) return 'Sem conexão com o servidor';
    if (status == 401) return 'Sessão expirada';
    if (status == 403) return 'Acesso negado';
    if (status == 404) return 'Recurso não encontrado';
    if (status == 409) return 'Ação já realizada';
    if (status == 422) return 'Dados inválidos';
    if (status >= 500) return 'Erro interno do servidor';
    return 'Erro inesperado';
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
    _dio.interceptors.add(ErrorInterceptor());
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get<T>(path, queryParameters: queryParams);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

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
