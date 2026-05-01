class DailyChallenge {
  final String date;
  final dynamic targetExercise; // Should map to ExerciseDetail or similar
  final int targetReps;
  final int? targetDurationSeconds;
  final double difficultyMultiplier;
  final String description;

  DailyChallenge({
    required this.date,
    required this.targetExercise,
    required this.targetReps,
    this.targetDurationSeconds,
    required this.difficultyMultiplier,
    required this.description,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      date: json['date'] as String,
      targetExercise: json['target_exercise'], 
      targetReps: json['target_reps'] as int,
      targetDurationSeconds: json['target_duration_seconds'] as int?,
      difficultyMultiplier: (json['difficulty_multiplier'] as num).toDouble(),
      description: json['description'] as String,
    );
  }
}
