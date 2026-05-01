import '../data/models/user_stats.dart';
import '../../../core/constants/exercises.dart';

/// 🧠 Adaptive Intelligence Logic
///
/// Scales workout intensity based on historical and real-time performance data.
class AdaptiveIntelligence {
  /// Calculate appropriate rep goal for next session
  static int calculateNextRepGoal(UserStats stats, ExerciseData exercise) {
    if (stats.totalWorkouts < 3) {
      return exercise.defaultReps;
    }

    // Scale factor based on level (higher level = higher default)
    double intensityMultiplier = 1.0 + (stats.level * 0.1);

    // Adjustment based on recent performance
    // If user's average reps are high, increase goal
    if (stats.totalReps / max(1, stats.totalWorkouts) >
        exercise.defaultReps * 1.5) {
      intensityMultiplier += 0.2;
    }

    return (exercise.baseIntensity * intensityMultiplier).round();
  }

  /// Rules for Level Promotion
  ///
  /// Beginner → Intermediate → Advanced
  static bool shouldPromoteLevel(UserStats stats) {
    // Basic requirement: XP threshold met
    if (stats.xp < stats.xpToNextLevel) {
      return false;
    }

    // Quality requirement: At least 3 full workouts in current level
    if (stats.totalWorkouts < stats.level * 5) {
      return false;
    }

    return true;
  }

  /// XP Award Calculation
  ///
  /// Awards XP based on:
  /// - Base completion (50 XP)
  /// - Accuracy Bonus (Up to 30 XP)
  /// - Tempo Bonus (Up to 20 XP)
  static int calculateXPGained(int reps, double avgAccuracy, double avgTempo) {
    int xp = 0;

    // Base completion
    xp += (reps * 2);

    // Accuracy Bonus
    if (avgAccuracy > 90) {
      xp += 30;
    } else if (avgAccuracy > 70) {
      xp += 15;
    }

    // Tempo Precision Bonus
    if (avgTempo > 85) {
      xp += 20;
    } else if (avgTempo > 60) {
      xp += 10;
    }

    return xp;
  }
}

// Simple max helper since standard dart math max is specific to types
T max<T extends num>(T a, T b) => a > b ? a : b;
