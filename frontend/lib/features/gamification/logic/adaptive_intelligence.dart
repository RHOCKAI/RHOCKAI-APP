import 'dart:math' as math;
import '../data/models/user_stats.dart';
import '../../../core/constants/exercises.dart';

/// 🧠 Adaptive Intelligence Logic
///
/// Scales workout intensity based on historical performance and user feedback.
class AdaptiveIntelligence {
  /// Calculate adaptive rep goal for next session based on level + feedback history
  static int calculateNextRepGoal(UserStats stats, ExerciseData exercise) {
    final baseReps = exercise.defaultReps;
    final modifier = stats.getDifficultyModifier(exercise.id);
    final levelBonus = 1.0 + ((stats.level - 1) * 0.05).clamp(0.0, 0.5);
    final adaptedReps = (baseReps * modifier * levelBonus).round();
    // Clamp to sensible bounds: never less than 3, never more than 50
    return adaptedReps.clamp(3, 50);
  }

  /// Calculate adaptive set goal
  static int calculateNextSetGoal(UserStats stats, ExerciseData exercise) {
    final base = exercise.defaultSets;
    final modifier = stats.getDifficultyModifier(exercise.id);
    if (modifier >= 1.4) {
      return base + 1;
    }
    return base;
  }

  /// Update difficulty modifier based on user's "Struggled / Perfect / Easy" feedback.
  /// Returns the updated modifier value (clamped 0.5 – 2.0).
  static double updateDifficultyModifier(
    UserStats stats,
    String exerciseId,
    DifficultyFeedback feedback,
  ) {
    final current = stats.getDifficultyModifier(exerciseId);
    double updated;

    switch (feedback) {
      case DifficultyFeedback.tooEasy:
        updated = current + 0.10; // +10% reps next time
        break;
      case DifficultyFeedback.tooHard:
        updated = current - 0.10; // -10% reps next time
        break;
      case DifficultyFeedback.perfect:
        // Small nudge upward for consistency reward
        updated = current + 0.03;
        break;
    }

    return updated.clamp(0.5, 2.0);
  }

  /// Determine the recommended difficulty tier for the next session
  static String recommendedDifficulty(UserStats stats) {
    if (stats.level >= 10) {
      return 'advanced';
    }
    if (stats.level >= 4) {
      return 'intermediate';
    }
    return 'beginner';
  }

  /// Whether the user should be promoted to the next level
  static bool shouldPromoteLevel(UserStats stats) {
    return stats.xp >= stats.xpToNextLevel &&
        stats.totalWorkouts >= stats.level * 3;
  }

  /// XP calculation — rewards reps, accuracy, tempo, streaks, and feedback
  static int calculateXPGained({
    required int reps,
    required double avgAccuracy,
    required double avgTempo,
    required int currentStreak,
    DifficultyFeedback? feedback,
  }) {
    int xp = 0;

    // Base: 2 XP per rep
    xp += reps * 2;

    // Accuracy bonus
    if (avgAccuracy >= 90) {
      xp += 30;
    } else if (avgAccuracy >= 75) {
      xp += 15;
    } else if (avgAccuracy >= 60) {
      xp += 5;
    }

    // Tempo bonus
    if (avgTempo >= 85) {
      xp += 20;
    } else if (avgTempo >= 60) {
      xp += 10;
    }

    // Streak multiplier bonus (caps at 5x streak)
    final streakBonus = math.min(currentStreak, 5) * 5;
    xp += streakBonus;

    // Feedback bonus — if user found it hard but pushed through
    if (feedback == DifficultyFeedback.tooHard) {
      xp += 10; // courage bonus
    } else if (feedback == DifficultyFeedback.perfect) {
      xp += 5; // consistency bonus
    }

    return xp;
  }
}
