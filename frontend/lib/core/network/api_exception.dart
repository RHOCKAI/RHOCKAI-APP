import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? type;

  ApiException({required this.message, this.statusCode, this.type});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode, Type: $type)';

  factory ApiException.fromDioError(DioException error) {
    String message = 'An unexpected error occurred';
    int? statusCode = error.response?.statusCode;
    String type = error.type.toString();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please check your internet.';
        break;
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map && data.containsKey('message')) {
          message = data['message'];
        } else if (statusCode == 401) {
          message = 'Session expired. Please login again.';
        } else if (statusCode == 403) {
          message = 'Access denied.';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
        } else if (statusCode != null && statusCode >= 500) {
          message = 'Server error. Please try again later.';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'Cannot connect to server. Please check your connection.';
        break;
      default:
        message = error.message ?? 'Network error';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      type: type,
    );
  }
}
