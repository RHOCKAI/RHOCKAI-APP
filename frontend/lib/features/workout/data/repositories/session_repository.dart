import 'package:rhockai/core/network/api_client.dart';
import '../../../camera_ai/session/session_model.dart';

class SessionRepository {
  final ApiClient _apiClient;

  SessionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<WorkoutSession>> getSessions(
      {int skip = 0, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '/sessions',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => WorkoutSession.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch sessions: $e');
    }
  }

  Future<WorkoutSession> getSession(int id) async {
    try {
      final response = await _apiClient.get('/sessions/$id');
      return WorkoutSession.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch session: $e');
    }
  }
}
