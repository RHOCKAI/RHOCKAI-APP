import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  static String get baseUrl => ApiConstants.baseUrl;

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 50),
          receiveTimeout: const Duration(seconds: 50),
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
        onError: (DioException error, handler) {
          // We pass the original error, but we'll wrap it in our logic in the call sites 
          // or we can wrap it in a DioException that contains our ApiException.
          debugPrint('❌ API Error: [${error.response?.statusCode}] ${error.message}');
          handler.next(error); 
        },
      ),
    );
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.patch(path, data: data, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
