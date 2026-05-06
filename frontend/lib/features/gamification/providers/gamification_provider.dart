import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_stats.dart';
import '../logic/adaptive_intelligence.dart';
import '../../../features/camera_ai/session/session_model.dart';

// ─────────────────────────────────────────────
// Result object returned after recording a workout
// ─────────────────────────────────────────────
class WorkoutResult {
  final int xpGained;
  final bool leveledUp;
  final int newLevel;
  final int newStreak;
  final UserStats updatedStats;

  WorkoutResult({
    required this.xpGained,
    required this.leveledUp,
    required this.newLevel,
    required this.newStreak,
    required this.updatedStats,
  });
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────
final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, AsyncValue<UserStats>>((ref) {
  return GamificationNotifier();
});

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────
class GamificationNotifier extends StateNotifier<AsyncValue<UserStats>> {
  static const _statsKey = 'user_gamification_stats_v2';

  GamificationNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  // ─── Load ───────────────────────────────────
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_statsKey);
      if (raw == null) {
        state = const AsyncValue.data(UserStats());
        return;
      }
      state = AsyncValue.data(UserStats.fromJson(jsonDecode(raw)));
    } catch (e) {
      state = const AsyncValue.data(UserStats());
    }
  }

  // ─── Save ───────────────────────────────────
  Future<void> _save(UserStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
      state = AsyncValue.data(stats);
    } catch (e) {
      debugPrint('GamificationProvider save error: $e');
    }
  }

  // ─── Record Workout ──────────────────────────
  /// Call this after every workout session.
  /// Returns a [WorkoutResult] with XP gained, streak, level-up info.
  Future<WorkoutResult> recordWorkout({
    required WorkoutSession session,
    DifficultyFeedback? feedback,
  }) async {
    final current = state.valueOrNull ?? const UserStats();

    // 1. Streak calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = current.lastWorkoutDate;
    int newStreak = current.currentStreak;

    if (last == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        newStreak = current.currentStreak; // already worked out today
      } else if (diff == 1) {
        newStreak = current.currentStreak + 1; // consecutive day
      } else {
        newStreak = 1; // streak broken
      }
    }

    final newLongest = newStreak > current.longestStreak
        ? newStreak
        : current.longestStreak;

    // 2. XP calculation
    final xpGained = AdaptiveIntelligence.calculateXPGained(
      reps: session.totalReps,
      avgAccuracy: session.averageAccuracy,
      avgTempo: session.averageTempoScore,
      currentStreak: newStreak,
      feedback: feedback,
    );

    // 3. Level-up logic
    int newXP = current.xp + xpGained;
    int newLevel = current.level;
    bool leveledUp = false;

    while (newXP >= newLevel * 100) {
      newXP -= newLevel * 100;
      newLevel++;
      leveledUp = true;
    }

    // 4. Update difficulty modifier for this exercise
    final exerciseId = session.exerciseType.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    final updatedModifiers = Map<String, double>.from(current.exerciseDifficultyModifier);
    if (feedback != null) {
      updatedModifiers[exerciseId] = AdaptiveIntelligence.updateDifficultyModifier(
        current,
        exerciseId,
        feedback,
      );
    }

    // 5. Update feedback history
    final updatedHistory = Map<String, List<String>>.from(
      current.exerciseFeedbackHistory.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
    if (feedback != null) {
      final history = updatedHistory[exerciseId] ?? [];
      history.add(feedback.name);
      if (history.length > 5) history.removeAt(0); // keep last 5
      updatedHistory[exerciseId] = history;
    }

    // 6. Build updated stats
    final updated = current.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      totalWorkouts: current.totalWorkouts + 1,
      totalReps: current.totalReps + session.totalReps,
      level: newLevel,
      xp: newXP,
      lastWorkoutDate: now,
      exerciseDifficultyModifier: updatedModifiers,
      exerciseFeedbackHistory: updatedHistory,
    );

    await _save(updated);

    return WorkoutResult(
      xpGained: xpGained,
      leveledUp: leveledUp,
      newLevel: newLevel,
      newStreak: newStreak,
      updatedStats: updated,
    );
  }

  // ─── Getters ─────────────────────────────────
  UserStats get stats => state.valueOrNull ?? const UserStats();
}
