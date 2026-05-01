import 'dart:convert';

/// Represents a single repetition data
class RepData {
  final int repNumber;
  final double accuracy;
  final List<String> formIssues;
  final double tempoScore;
  final DateTime timestamp;

  RepData({
    required this.repNumber,
    required this.accuracy,
    required this.formIssues,
    required this.tempoScore,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'rep_number': repNumber,
        'accuracy': accuracy,
        'form_issues': formIssues,
        'tempo_score': tempoScore,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RepData.fromJson(Map<String, dynamic> json) {
    return RepData(
      repNumber: json['rep_number'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      formIssues: List<String>.from(json['form_issues'] ?? []),
      tempoScore: (json['tempo_score'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Represents a complete workout session
class WorkoutSession {
  final String id;
  final String exerciseType;
  final DateTime startTime;
  DateTime? endTime;

  int totalReps;
  int correctReps;
  double averageAccuracy;
  double averageTempoScore;
  int caloriesBurned;
  Duration duration;
  String? videoUrl;
  bool sharedToSocial;

  List<RepData> reps;

  WorkoutSession({
    required this.id,
    required this.exerciseType,
    required this.startTime,
    this.endTime,
    this.totalReps = 0,
    this.correctReps = 0,
    this.averageAccuracy = 0.0,
    this.averageTempoScore = 0.0,
    this.caloriesBurned = 0,
    this.duration = Duration.zero,
    this.videoUrl,
    this.sharedToSocial = false,
    this.reps = const [],
  });

  void addRep(RepData rep) {
    reps = [...reps, rep]; // Create new list to trigger updates
    totalReps++;
    if (rep.accuracy > 70) {
      correctReps++;
    }
    _recalculateMetrics();
  }

  void _recalculateMetrics() {
    // Average accuracy
    if (reps.isNotEmpty) {
      averageAccuracy =
          reps.map((r) => r.accuracy).reduce((a, b) => a + b) / reps.length;
      averageTempoScore =
          reps.map((r) => r.tempoScore).reduce((a, b) => a + b) / reps.length;
    }

    // Duration
    if (endTime != null) {
      duration = endTime!.difference(startTime);
    }

    // Calories (simple formula: 0.05 cal per rep)
    // Adjust based on exercise type and user weight in real app
    caloriesBurned = (totalReps * 0.5).round();
  }

  void complete() {
    endTime = DateTime.now();
    _recalculateMetrics();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise_type': exerciseType,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'total_reps': totalReps,
        'correct_reps': correctReps,
        'average_accuracy': averageAccuracy,
        'average_tempo_score': averageTempoScore,
        'calories_burned': caloriesBurned,
        'duration_seconds': duration.inSeconds,
        'video_url': videoUrl,
        'shared_to_social': sharedToSocial ? 1 : 0,
        'reps_data': jsonEncode(reps.map((r) => r.toJson()).toList()),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    // Parse reps data
    List<RepData> repsList = [];
    if (json['reps_data'] != null) {
      final repsDataString = json['reps_data'] as String;
      final repsDataList = jsonDecode(repsDataString) as List;
      repsList = repsDataList
          .map((r) => RepData.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return WorkoutSession(
      id: json['id'] as String,
      exerciseType: json['exercise_type'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      totalReps: json['total_reps'] as int? ?? 0,
      correctReps: json['correct_reps'] as int? ?? 0,
      averageAccuracy: (json['average_accuracy'] as num?)?.toDouble() ?? 0.0,
      averageTempoScore:
          (json['average_tempo_score'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: json['calories_burned'] as int? ?? 0,
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 0),
      videoUrl: json['video_url'] as String?,
      sharedToSocial: (json['shared_to_social'] as int? ?? 0) == 1,
      reps: repsList,
    );
  }

  /// Convert to format for backend API
  Map<String, dynamic> toApiJson() => {
        'exercise_type': exerciseType,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'total_reps': totalReps,
        'correct_reps': correctReps,
        'average_accuracy': averageAccuracy,
        'average_tempo_score': averageTempoScore,
        'calories_burned': caloriesBurned,
        'duration_seconds': duration.inSeconds,
        'video_url': videoUrl,
        'shared_to_social': sharedToSocial,
        'reps_data': reps.map((r) => r.toJson()).toList(),
      };
}
