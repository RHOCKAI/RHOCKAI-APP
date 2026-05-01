import 'package:rhockai/core/network/api_client.dart';
import 'package:rhockai/features/camera_ai/session/session_storage.dart';
import '../models/progress_models.dart';

class ProgressRepository {
  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;

  ProgressRepository({ApiClient? apiClient, SessionStorage? sessionStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _sessionStorage = sessionStorage ?? SessionStorage();

  /// Get daily progress data for charts
  Future<List<ProgressData>> getProgress({int days = 30}) async {
    try {
      final response = await _apiClient.get(
        '/analytics/progress',
        queryParameters: {'days': days},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => ProgressData.fromJson(json)).toList();
    } catch (e) {
      // Fallback to local storage
      final sessions = await _sessionStorage.getAllSessions(limit: days);
      return sessions
          .map((s) => ProgressData(
                date: s.startTime.toIso8601String(),
                sessions: 1,
                reps: s.totalReps,
                calories: s.caloriesBurned,
                accuracy: s.averageAccuracy,
              ))
          .toList();
    }
  }

  /// Get aggregate statistics
  Future<SessionStats> getStats({int days = 7}) async {
    try {
      final response = await _apiClient.get(
        '/analytics/stats',
        queryParameters: {'days': days},
      );

      return SessionStats.fromJson(response.data);
    } catch (e) {
      // Fallback to local storage stats
      final stats = await _sessionStorage.getTotalStats();
      return SessionStats(
        totalSessions: stats['total_sessions'] ?? 0,
        totalReps: stats['total_reps'] ?? 0,
        totalCalories: stats['total_calories'] ?? 0,
        averageAccuracy: (stats['avg_accuracy'] as num?)?.toDouble() ?? 0.0,
        totalDurationMinutes: ((stats['total_duration'] as int?) ?? 0) ~/ 60,
      );
    }
  }
}
