/// Lightweight summary of video analysis results
/// 
/// Designed to be:
/// - Concise (no heavy data structures)
/// - User-friendly (ready for display)
/// - Serializable (can be saved/shared)
class SessionReport {
  /// Total repetitions detected
  final int totalReps;
  
  /// Repetitions with good form (>70% accuracy)
  final int correctReps;
  
  /// Average form accuracy across all reps (0-100%)
  final double averageAccuracy;
  
  /// Video duration
  final Duration duration;
  
  /// Key form corrections (max 5)
  /// e.g., "Keep your back straight", "Don't let knees cave inward"
  final List<String> keyCorrections;
  
  /// Additional metrics for detailed analysis
  /// e.g., {'tempo_score': 85.0, 'consistency': 92.0}
  final Map<String, double> metrics;
  
  /// Exercise type analyzed
  final String exerciseType;
  
  const SessionReport({
    required this.totalReps,
    required this.correctReps,
    required this.averageAccuracy,
    required this.duration,
    required this.keyCorrections,
    required this.exerciseType,
    this.metrics = const {},
  });
  
  /// Accuracy percentage (0-100%)
  double get accuracyPercentage => averageAccuracy;
  
  /// Success rate (correct reps / total reps)
  double get successRate => 
      totalReps > 0 ? (correctReps / totalReps) * 100 : 0.0;
  
  /// Whether the session was successful (>70% accuracy)
  bool get isSuccessful => averageAccuracy >= 70.0;
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'total_reps': totalReps,
        'correct_reps': correctReps,
        'average_accuracy': averageAccuracy,
        'duration_seconds': duration.inSeconds,
        'key_corrections': keyCorrections,
        'exercise_type': exerciseType,
        'metrics': metrics,
      };
  
  /// Create from JSON
  factory SessionReport.fromJson(Map<String, dynamic> json) {
    return SessionReport(
      totalReps: json['total_reps'] as int,
      correctReps: json['correct_reps'] as int,
      averageAccuracy: (json['average_accuracy'] as num).toDouble(),
      duration: Duration(seconds: json['duration_seconds'] as int),
      keyCorrections: List<String>.from(json['key_corrections'] ?? []),
      exerciseType: json['exercise_type'] as String,
      metrics: Map<String, double>.from(
        (json['metrics'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            ) ??
            {},
      ),
    );
  }
  
  /// Create empty report
  factory SessionReport.empty(String exerciseType) {
    return SessionReport(
      totalReps: 0,
      correctReps: 0,
      averageAccuracy: 0.0,
      duration: Duration.zero,
      keyCorrections: [],
      exerciseType: exerciseType,
    );
  }
  
  @override
  String toString() {
    return 'SessionReport(reps: $totalReps, accuracy: ${averageAccuracy.toStringAsFixed(1)}%)';
  }
}
