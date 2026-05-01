class ProgressData {
  final String date;
  final int sessions;
  final int reps;
  final int calories;
  final double accuracy;

  ProgressData({
    required this.date,
    required this.sessions,
    required this.reps,
    required this.calories,
    required this.accuracy,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      date: json['date'] as String,
      sessions: json['sessions'] as int,
      reps: json['reps'] as int,
      calories: json['calories'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }
}

class SessionStats {
  final int totalSessions;
  final int totalReps;
  final int totalCalories;
  final double averageAccuracy;
  final int totalDurationMinutes;

  SessionStats({
    required this.totalSessions,
    required this.totalReps,
    required this.totalCalories,
    required this.averageAccuracy,
    required this.totalDurationMinutes,
  });

  factory SessionStats.fromJson(Map<String, dynamic> json) {
    return SessionStats(
      totalSessions: json['total_sessions'] as int,
      totalReps: json['total_reps'] as int,
      totalCalories: json['total_calories'] as int,
      averageAccuracy: (json['average_accuracy'] as num).toDouble(),
      totalDurationMinutes: json['total_duration_minutes'] as int,
    );
  }
}
