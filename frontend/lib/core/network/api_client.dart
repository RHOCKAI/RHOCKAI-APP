import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static String get baseUrl => ApiConstants.baseUrl;

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Log request details for debugging
          debugPrint('🌐 API Request: [${options.method}] ${options.uri}');

          // Add auth token
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '✅ API Response: [${response.statusCode}] ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Enhanced error logging for connectivity issues
          final path = error.requestOptions.path;
          final method = error.requestOptions.method;

          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            debugPrint(
                '❌ API Timeout: [$method] $path - Check backend responsiveness.');
          } else if (error.type == DioExceptionType.connectionError) {
            debugPrint(
                '❌ API Connection Error: [$method] $path - Host unreachable. Current URL: $baseUrl');
          } else {
            debugPrint(
                '❌ API Error: [${error.response?.statusCode}] [$method] $path - ${error.message}');
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    return await _dio.post(path, data: data, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    return await _dio.patch(path, data: data, options: options);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}
