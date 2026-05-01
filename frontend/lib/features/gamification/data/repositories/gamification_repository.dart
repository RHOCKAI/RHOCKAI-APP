import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_stats.dart';
import '../models/leaderboard_entry.dart';
import '../models/daily_challenge.dart';
import '../models/rating_update_response.dart';

class GamificationRepository {
  static const String _statsKey = 'user_gamification_stats';
  
  Future<UserStats> getUserStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_statsKey);
    
    if (statsJson == null) {
      return const UserStats();
    }
    
    try {
      return UserStats.fromJson(jsonDecode(statsJson));
    } catch (e) {
      return const UserStats();
    }
  }
  
  Future<void> saveUserStats(UserStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  // --- Remote API Calls for Gamification ---

  Future<List<LeaderboardEntry>> getDailyLeaderboard(ApiClient apiClient, {int limit = 50}) async {
    try {
      final response = await apiClient.get(
        '/gamification/leaderboard/daily',
        queryParameters: {'limit': limit},
      );
      
      return (response.data as List)
          .map((json) => LeaderboardEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      rethrow;
    }
  }

  Future<DailyChallenge> getDailyChallenge(ApiClient apiClient) async {
    try {
      final response = await apiClient.get('/gamification/daily-challenge');
      return DailyChallenge.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching daily challenge: $e');
      rethrow;
    }
  }

  Future<FitnessRatingUpdateResponse> recalculateRating(ApiClient apiClient) async {
    try {
      final response = await apiClient.post('/gamification/recalculate-rating');
      return FitnessRatingUpdateResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error recalculating rating: $e');
      rethrow;
    }
  }
}
