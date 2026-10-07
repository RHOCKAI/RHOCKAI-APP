import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Represents the quality of the current pose detection.
enum PoseQuality {
  good,
  tooClose,
  partiallyHidden,
  noPersonDetected,
}

class PoseQualityResult {
  final PoseQuality quality;
  final String? message;

  const PoseQualityResult(this.quality, [this.message]);
}

/// Checks the pose for proximity, visibility, and lighting issues.
class PoseQualityChecker {
  final double imageHeight;

  PoseQualityChecker({required this.imageHeight});

  /// Evaluates the current pose and returns a quality result and feedback string.
  PoseQualityResult check(Pose pose, {String? exerciseType}) {
    final landmarks = pose.landmarks.values.toList();
    if (landmarks.isEmpty) {
      return const PoseQualityResult(PoseQuality.noPersonDetected,
          'Position yourself in front of the camera');
    }

    final allLowConfidence = landmarks.every((l) => l.likelihood < 0.25);
    if (allLowConfidence) {
      return const PoseQualityResult(PoseQuality.noPersonDetected,
          'Position yourself in front of the camera');
    }

    final isFloorExercise = exerciseType != null &&
        (exerciseType.toLowerCase().contains('pushup') ||
            exerciseType.toLowerCase().contains('plank') ||
            exerciseType.toLowerCase().contains('bridge'));

    final keyLandmarkTypes = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    ];

    int visibleKeyLandmarks = 0;
    for (final type in keyLandmarkTypes) {
      final lm = pose.landmarks[type];
      if (lm != null && lm.likelihood >= 0.3) {
        visibleKeyLandmarks++;
      }
    }

    // Need at least 2 key body joints visible to proceed
    if (visibleKeyLandmarks < 2) {
      return const PoseQualityResult(
          PoseQuality.partiallyHidden, 'Make sure your body is visible');
    }

    // Only apply standing vertical height check for non-floor exercises
    if (!isFloorExercise) {
      final nose = pose.landmarks[PoseLandmarkType.nose];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      if (nose != null && (leftAnkle != null || rightAnkle != null)) {
        final lowestY = [leftAnkle?.y, rightAnkle?.y]
            .whereType<double>()
            .reduce((a, b) => a > b ? a : b);
        final highestY = nose.y;

        final bodyHeight = (lowestY - highestY).abs();
        if (imageHeight > 0 && (bodyHeight / imageHeight) > 0.95) {
          return const PoseQualityResult(PoseQuality.tooClose, 'Step back a bit');
        }
      }
    }

    return const PoseQualityResult(PoseQuality.good);
  }

  /// Cleans up resources.
  void dispose() {}
}
