import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging
class Logger {
  static const bool _enableLogs = kDebugMode;

  /// Log info message
  static void info(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ $prefix$message');
    }
  }

  /// Log success message
  static void success(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('✅ $prefix$message');
    }
  }

  /// Log warning message
  static void warning(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ $prefix$message');
    }
  }

  /// Log error message
  static void error(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ $prefix$message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log debug message
  static void debug(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🐛 $prefix$message');
    }
  }

  /// Log network request
  static void network(String method, String url, {Map<String, dynamic>? data}) {
    if (_enableLogs) {
      debugPrint('🌐 $method $url');
      if (data != null) {
        debugPrint('Data: $data');
      }
    }
  }

  /// Log AI/ML processing
  static void ai(String message, {Map<String, dynamic>? metrics}) {
    if (_enableLogs) {
      debugPrint('🤖 $message');
      if (metrics != null) {
        debugPrint('Metrics: $metrics');
      }
    }
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    if (_enableLogs) {
      debugPrint('⏱️ $operation took ${duration.inMilliseconds}ms');
    }
  }
}

/// Extension for easy logging
extension LoggerExtension on Object {
  void log([String? tag]) {
    Logger.info(toString(), tag: tag);
  }
}
