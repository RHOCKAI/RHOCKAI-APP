import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:rhockai/core/network/api_client.dart';
import 'session_model.dart';
import 'session_storage.dart';

import '../../gamification/services/streak_service.dart';
import '../../gamification/services/level_service.dart';
import '../../gamification/data/repositories/gamification_repository.dart';

/// Session state notifier
class SessionNotifier extends StateNotifier<WorkoutSession?> {
  final SessionStorage _localStorage = SessionStorage();
  final StreakService _streakService;
  final LevelService _levelService;

  SessionNotifier(this._streakService, this._levelService) : super(null);

  /// Start a new workout session
  void startSession(String exerciseType) {
    state = WorkoutSession(
      id: const Uuid().v4(),
      exerciseType: exerciseType,
      startTime: DateTime.now(),
    );
  }

  /// Add a rep to the current session
  void addRep(RepData rep) {
    if (state == null) {
      return;
    }

    // Create new session with updated data
    state = WorkoutSession(
      id: state!.id,
      exerciseType: state!.exerciseType,
      startTime: state!.startTime,
      endTime: state!.endTime,
      totalReps: state!.totalReps + 1,
      correctReps:
          rep.accuracy > 70 ? state!.correctReps + 1 : state!.correctReps,
      averageAccuracy: state!.reps.isEmpty
          ? rep.accuracy
          : ((state!.averageAccuracy * state!.reps.length) + rep.accuracy) /
              (state!.reps.length + 1),
      caloriesBurned: state!.caloriesBurned,
      duration: state!.duration,
      reps: [...state!.reps, rep],
    );
  }

  /// Complete the current session
  Future<void> completeSession() async {
    if (state == null) {
      return;
    }

    // Mark as complete
    state!.complete();

    try {
      // Save to local storage
      await _localStorage.saveSession(state!);

      // Try to sync to backend
      await _syncToBackend(state!);
    } catch (e) {
      debugPrint('Error saving session: $e');
      // Session is already in local storage, will sync later
    }

    // Update Gamification Stats
    try {
      final repo = GamificationRepository();
      var stats = await repo.getUserStats();

      // Update Streak
      stats = await _streakService.updateStreakAfterWorkout(stats);

      // Calculate XP
      final xpEarned = _levelService.calculateXp(
        state!.totalReps,
        state!.averageAccuracy,
        tempoScore: state!.averageTempoScore,
      );

      // Update Level/XP
      stats = _levelService.addXp(stats, xpEarned);

      await repo.saveUserStats(stats);

      // Show Level Up Dialog if applicable (handled by UI listener)
    } catch (e) {
      debugPrint('Error updating gamification stats: $e');
    }

    // Keep state for display, but mark as completed
    state = state;
  }

  /// Cancel the current session
  void cancelSession() {
    state = null;
  }

  /// Reset session (for retry)
  void resetSession() {
    if (state != null) {
      state = WorkoutSession(
        id: state!.id,
        exerciseType: state!.exerciseType,
        startTime: state!.startTime,
      );
    }
  }

  Future<void> _syncToBackend(WorkoutSession session) async {
    try {
      final apiClient = ApiClient();

      // Create session on backend
      final createResponse = await apiClient.post(
        '/workouts/sessions',
        data: {
          'exercise_type': session.exerciseType,
          'start_time': session.startTime.toIso8601String(),
        },
      );

      final sessionId = createResponse.data['id'];

      // Update with completion data
      await apiClient.patch(
        '/workouts/sessions/$sessionId',
        data: session.toApiJson(),
      );

      // Mark as synced in local storage
      await _localStorage.markAsSynced(session.id);
    } catch (e) {
      debugPrint('Error syncing workout session: $e');
      // Re-throw to be handled by completeSession if needed,
      // though completeSession currently just logs it.
    }
  }
}

/// Provider for session state
final sessionProvider =
    StateNotifierProvider<SessionNotifier, WorkoutSession?>((ref) {
  final streakService = ref.watch(streakServiceProvider);
  final levelService = ref.watch(levelServiceProvider);
  return SessionNotifier(streakService, levelService);
});

/// Provider for session storage
final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage();
});

/// Provider for getting all sessions
final allSessionsProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final storage = ref.watch(sessionStorageProvider);
  return await storage.getAllSessions();
});

/// Provider for getting total stats
final totalStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final storage = ref.watch(sessionStorageProvider);
  return await storage.getTotalStats();
});

/// Provider for getting pending sessions (not synced)
final pendingSessionsProvider =
    FutureProvider<List<WorkoutSession>>((ref) async {
  final storage = ref.watch(sessionStorageProvider);
  return await storage.getPendingSessions();
});

/// Combined provider that merges historical stats with the current active session
final combinedStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final historicalStatsAsync = ref.watch(totalStatsProvider);
  final currentSession = ref.watch(sessionProvider);

  return historicalStatsAsync.whenData((stats) {
    if (currentSession == null) {
      return stats;
    }

    // Merge current session into stats
    final merged = Map<String, dynamic>.from(stats);
    merged['total_sessions'] = (stats['total_sessions'] ?? 0) + 1;
    merged['total_calories'] =
        (stats['total_calories'] ?? 0) + currentSession.caloriesBurned;

    // Recalculate average accuracy
    final historicalCount = stats['total_sessions'] ?? 0;
    final historicalAvg = (stats['avg_accuracy'] as num?)?.toDouble() ?? 0.0;

    merged['average_accuracy'] =
        ((historicalAvg * historicalCount) + currentSession.averageAccuracy) /
            (historicalCount + 1);

    return merged;
  });
});
