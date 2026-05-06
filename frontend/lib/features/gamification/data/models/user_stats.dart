import 'dart:convert';

/// Difficulty feedback a user gives after a workout
enum DifficultyFeedback { tooEasy, perfect, tooHard }

class UserStats {
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final int totalReps;
  final int level;
  final int xp;
  final DateTime? lastWorkoutDate;

  /// Per-exercise difficulty history: exerciseId → list of recent feedbacks (last 5)
  final Map<String, List<String>> exerciseFeedbackHistory;

  /// Per-exercise rep modifier: exerciseId → multiplier (e.g. 1.2 = 20% more reps)
  final Map<String, double> exerciseDifficultyModifier;

  const UserStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWorkouts = 0,
    this.totalReps = 0,
    this.level = 1,
    this.xp = 0,
    this.lastWorkoutDate,
    this.exerciseFeedbackHistory = const {},
    this.exerciseDifficultyModifier = const {},
  });

  UserStats copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalWorkouts,
    int? totalReps,
    int? level,
    int? xp,
    DateTime? lastWorkoutDate,
    Map<String, List<String>>? exerciseFeedbackHistory,
    Map<String, double>? exerciseDifficultyModifier,
  }) {
    return UserStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalReps: totalReps ?? this.totalReps,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      exerciseFeedbackHistory: exerciseFeedbackHistory ?? this.exerciseFeedbackHistory,
      exerciseDifficultyModifier: exerciseDifficultyModifier ?? this.exerciseDifficultyModifier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalWorkouts': totalWorkouts,
      'totalReps': totalReps,
      'level': level,
      'xp': xp,
      'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
      'exerciseFeedbackHistory': exerciseFeedbackHistory
          .map((k, v) => MapEntry(k, jsonEncode(v))),
      'exerciseDifficultyModifier': exerciseDifficultyModifier,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['exerciseFeedbackHistory'] as Map<String, dynamic>? ?? {};
    final history = rawHistory.map((k, v) {
      final decoded = jsonDecode(v as String) as List;
      return MapEntry(k, decoded.cast<String>());
    });

    final rawModifiers = json['exerciseDifficultyModifier'] as Map<String, dynamic>? ?? {};
    final modifiers = rawModifiers.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return UserStats(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalWorkouts: json['totalWorkouts'] ?? 0,
      totalReps: json['totalReps'] ?? 0,
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      lastWorkoutDate: json['lastWorkoutDate'] != null
          ? DateTime.parse(json['lastWorkoutDate'])
          : null,
      exerciseFeedbackHistory: history,
      exerciseDifficultyModifier: modifiers,
    );
  }

  /// XP needed to advance to next level (scales with level)
  int get xpToNextLevel => level * 100;

  /// Progress within current level (0.0 → 1.0)
  double get levelProgress => (xp / xpToNextLevel).clamp(0.0, 1.0);

  /// Human-readable rank title based on level
  String get rankTitle {
    if (level >= 20) return 'ELITE';
    if (level >= 15) return 'MASTER';
    if (level >= 10) return 'PRO';
    if (level >= 5) return 'WARRIOR';
    if (level >= 3) return 'ATHLETE';
    return 'ROOKIE';
  }

  /// Get the difficulty modifier for a specific exercise (default 1.0)
  double getDifficultyModifier(String exerciseId) {
    return exerciseDifficultyModifier[exerciseId] ?? 1.0;
  }
}
