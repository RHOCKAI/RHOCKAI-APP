import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_config.dart';

/// Represents the 4-phase state machine for rep counting.
enum RepPhase {
  up,
  goingDown,
  down,
  goingUp,
}

/// Handles rep counting with a state machine and confidence gating.
class RepCounter {
  final String exerciseType;
  RepPhase _phase = RepPhase.up;
  int _reps = 0;

  RepCounter({required this.exerciseType});

  /// Gets the current completed rep count.
  int get currentReps => _reps;

  /// Gets the current movement phase.
  RepPhase get currentPhase => _phase;

  /// Processes the current pose and updates the state machine.
  /// Returns the current angle calculated, or -1.0 if the signal is invalid.
  double processPose(Pose pose) {
    if (exerciseType == 'plank') {
      return -1.0;
    }

    final angle = _getExerciseAngle(pose);
    if (angle < 0) {
      return -1.0;
    }

    final thresholds = exerciseType == 'squat'
        ? ExerciseThresholds.squat
        : ExerciseThresholds.pushup;

    _updateStateMachine(angle, thresholds);
    return angle;
  }

  void _updateStateMachine(double angle, ExerciseThresholds thresholds) {
    switch (_phase) {
      case RepPhase.up:
        if (angle < thresholds.upAngle - PoseConfig.angleHysteresis) {
          _phase = RepPhase.goingDown;
        }
        break;
      case RepPhase.goingDown:
        if (angle <= thresholds.downAngle + PoseConfig.angleHysteresis) {
          _phase = RepPhase.down;
        } else if (angle >= thresholds.upAngle) {
          _phase = RepPhase.up;
        }
        break;
      case RepPhase.down:
        if (angle > thresholds.downAngle + PoseConfig.angleHysteresis) {
          _phase = RepPhase.goingUp;
        }
        break;
      case RepPhase.goingUp:
        if (angle >= thresholds.upAngle - PoseConfig.angleHysteresis) {
          _reps++;
          _phase = RepPhase.up;
        } else if (angle <= thresholds.downAngle) {
          _phase = RepPhase.down;
        }
        break;
    }
  }

  double _getExerciseAngle(Pose pose) {
    if (exerciseType == 'squat') {
      return _calculateAngleConfidenceGated(
        pose,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
      );
    } else {
      return _calculateAngleConfidenceGated(
        pose,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
      );
    }
  }

  /// Calculates angle between 3 points. Returns -1 if any landmark lacks confidence.
  double _calculateAngleConfidenceGated(
    Pose pose,
    PoseLandmarkType aType,
    PoseLandmarkType bType,
    PoseLandmarkType cType,
  ) {
    final a = pose.landmarks[aType];
    final b = pose.landmarks[bType];
    final c = pose.landmarks[cType];

    if (a == null || b == null || c == null) {
      return -1.0;
    }

    if (a.likelihood < PoseConfig.minTrackingConfidence ||
        b.likelihood < PoseConfig.minTrackingConfidence ||
        c.likelihood < PoseConfig.minTrackingConfidence) {
      return -1.0;
    }

    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    var degrees = (radians * 180.0 / pi).abs();

    if (degrees > 180.0) {
      degrees = 360.0 - degrees;
    }
    return degrees;
  }

  /// Resets rep count and phase.
  void reset() {
    _reps = 0;
    _phase = RepPhase.up;
  }

  /// Cleans up resources.
  void dispose() {
    reset();
  }
}
