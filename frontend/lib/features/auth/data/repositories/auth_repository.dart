import 'dart:convert';
import 'package:rhockai/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authentication repository
class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required int age,
    String? gender,
    int? height,
    int? weight,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'age': age,
        'gender': gender ?? 'other',
        'height': height,
        'weight': weight,
        'fitness_level': 'beginner',
      });

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final detail = e.response!.data['detail'];
        if (detail != null && (detail.toString().contains('SELECT') || detail.toString().contains('column'))) {
          throw Exception('Database sync error on server. Please contact support.');
        }
        throw Exception(detail ?? 'Registration failed');
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      // Backend expects JSON at /auth/login for direct authentication
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['access_token'];

      // Save token securely
      await _storage.write(key: 'auth_token', value: token);

      // Optionally save user email
      await _storage.write(key: 'user_email', value: email);
    } on DioException catch (e) {
      if (e.response != null) {
        final detail = e.response!.data['detail'];
        if (detail != null && (detail.toString().contains('SELECT') || detail.toString().contains('column'))) {
          throw Exception('Database sync error on server. Please contact support.');
        }
        throw Exception(detail ?? 'Login failed');
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Login with Google
  Future<void> loginWithGoogle(String idToken) async {
    try {
      final response = await _apiClient.post(
        '/auth/google',
        data: {'id_token': idToken},
      );

      final token = response.data['access_token'];

      // Save token securely
      await _storage.write(key: 'auth_token', value: token);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['detail'] ?? 'Google login failed');
      }
      throw Exception('Network error');
    }
  }

  /// Login with Apple
  Future<void> loginWithApple(String idToken, {String? email, String? fullName}) async {
    try {
      final response = await _apiClient.post(
        '/auth/apple',
        data: {
          'id_token': idToken,
          if (email != null) 'email': email,
          if (fullName != null) 'full_name': fullName,
        },
      );

      final token = response.data['access_token'];

      // Save token securely
      await _storage.write(key: 'auth_token', value: token);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['detail'] ?? 'Apple login failed');
      }
      throw Exception('Network error');
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not logged in');
      }

      final response = await _apiClient.get(
        '/auth/me',
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired
        await logout();
        throw Exception('Session expired. Please login again.');
      }
      
      // If the backend returns a database error or SQL dump, don't show it to the user
      final errorDetail = e.response?.data?['detail'];
      if (errorDetail != null && (errorDetail.toString().contains('SELECT') || errorDetail.toString().contains('column'))) {
        throw Exception('Database sync error. Please run the database fix script on the server.');
      }
      
      throw Exception('Failed to get user profile. ${e.message}');
    }
  }

  /// Send password reset email
  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response!.data['detail'] ?? 'Failed to send reset email');
      }
      throw Exception('Network error');
    }
  }

  /// Reset password using token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post('/auth/reset-password', data: {
        'token': token,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response!.data['detail'] ?? 'Failed to reset password');
      }
      throw Exception('Network error');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? gender,
    int? age,
    int? height,
    int? weight,
    String? fitnessLevel,
    bool? isOnboarded,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Not logged in');
      }

      final response = await _apiClient.patch(
        '/auth/me',
        data: {
          if (fullName != null) 'full_name': fullName,
          if (gender != null) 'gender': gender,
          if (age != null) 'age': age,
          if (height != null) 'height': height,
          if (weight != null) 'weight': weight,
          if (fitnessLevel != null) 'fitness_level': fitnessLevel,
          if (isOnboarded != null) 'is_onboarded': isOnboarded,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data;
    } on DioException {
      throw Exception('Failed to update profile');
    }
  }

  /// Logout (clear stored token)
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_email');
  }

  /// Check if user is logged in and token is not expired
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      return false;
    }

    try {
      // Simple JWT parse to check exp claim
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      final payload = parts[1];
      // Normalize base64
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 0:
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        default:
          return false;
      }

      final decodedString = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decodedString);

      if (json['exp'] != null) {
        final exp = DateTime.fromMillisecondsSinceEpoch(json['exp'] * 1000);
        if (DateTime.now().isAfter(exp)) {
          await logout();
          return false;
        }
      }
      return true;
    } catch (e) {
      return false; // Invalid token format
    }
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Get stored email
  Future<String?> getEmail() async {
    return await _storage.read(key: 'user_email');
  }
}
