/// Configuration constants for the pose detection pipeline.
class PoseConfig {
  const PoseConfig._();

  /// Minimum confidence threshold for considering a pose valid.
  static const double minPoseConfidence = 0.6;

  /// Minimum confidence for detecting the presence of a person.
  static const double minPresenceConfidence = 0.6;

  /// Minimum confidence required for tracking individual landmarks.
  static const double minTrackingConfidence = 0.6;

  /// Hysteresis buffer in degrees to prevent boundary oscillation.
  static const double angleHysteresis = 10.0;

  /// Maximum framerate to process to prevent frame queuing on low-end devices.
  static const int maxProcessFps = 24;
}

/// Thresholds for different exercises.
class ExerciseThresholds {
  final double downAngle;
  final double upAngle;

  const ExerciseThresholds({
    required this.downAngle,
    required this.upAngle,
  });

  /// Squat: down=100°, up=160° (knee angle)
  static const squat = ExerciseThresholds(downAngle: 100.0, upAngle: 160.0);

  /// Pushup: down=90°, up=160° (elbow angle)
  static const pushup = ExerciseThresholds(downAngle: 90.0, upAngle: 160.0);
}

/// Wraps print calls so they compile away in release mode.
void debugLog(String message) {
  assert(() {
    // ignore: avoid_print
    print('[Rhockai] $message');
    return true;
  }());
}
