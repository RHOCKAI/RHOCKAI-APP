import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api/v1';
  
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  
  // Payment Endpoints
  static const String checkout = '/payments/checkout';
  static const String plans = '/payments/plans';
  
  // Workout Endpoints
  static const String sessions = '/workouts/sessions';
  static const String exercises = '/workouts/exercises';
}
