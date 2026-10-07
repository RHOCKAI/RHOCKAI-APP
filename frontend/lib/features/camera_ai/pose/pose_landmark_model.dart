import 'dart:ui' show Offset;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;

class PoseLandmark {
  final double x;
  final double y;
  final double z;
  final double likelihood;

  PoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.likelihood,
  });

  Offset get position => Offset(x, y);

  factory PoseLandmark.fromMLKit(mlkit.PoseLandmark landmark) {
    return PoseLandmark(
      x: landmark.x,
      y: landmark.y,
      z: landmark.z,
      likelihood: landmark.likelihood,
    );
  }
}

class PoseLandmarks {
  final Map<mlkit.PoseLandmarkType, PoseLandmark> landmarks;

  PoseLandmarks({required this.landmarks});

  factory PoseLandmarks.fromMLKit(mlkit.Pose pose) {
    final map = <mlkit.PoseLandmarkType, PoseLandmark>{};
    pose.landmarks.forEach((type, landmark) {
      map[type] = PoseLandmark.fromMLKit(landmark);
    });
    return PoseLandmarks(landmarks: map);
  }

  PoseLandmark? getLandmark(mlkit.PoseLandmarkType type) => landmarks[type];

  PoseLandmark get leftShoulder =>
      landmarks[mlkit.PoseLandmarkType.leftShoulder] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get rightShoulder =>
      landmarks[mlkit.PoseLandmarkType.rightShoulder] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get leftElbow =>
      landmarks[mlkit.PoseLandmarkType.leftElbow] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get rightElbow =>
      landmarks[mlkit.PoseLandmarkType.rightElbow] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get leftWrist =>
      landmarks[mlkit.PoseLandmarkType.leftWrist] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get rightWrist =>
      landmarks[mlkit.PoseLandmarkType.rightWrist] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get leftHip =>
      landmarks[mlkit.PoseLandmarkType.leftHip] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get rightHip =>
      landmarks[mlkit.PoseLandmarkType.rightHip] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get leftKnee =>
      landmarks[mlkit.PoseLandmarkType.leftKnee] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get rightKnee =>
      landmarks[mlkit.PoseLandmarkType.rightKnee] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get leftAnkle =>
      landmarks[mlkit.PoseLandmarkType.leftAnkle] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get rightAnkle =>
      landmarks[mlkit.PoseLandmarkType.rightAnkle] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get leftHeel =>
      landmarks[mlkit.PoseLandmarkType.leftHeel] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get rightHeel =>
      landmarks[mlkit.PoseLandmarkType.rightHeel] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get leftFootIndex =>
      landmarks[mlkit.PoseLandmarkType.leftFootIndex] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get rightFootIndex =>
      landmarks[mlkit.PoseLandmarkType.rightFootIndex] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);
  PoseLandmark get nose =>
      landmarks[mlkit.PoseLandmarkType.nose] ??
      PoseLandmark(x: 0, y: 0, z: 0, likelihood: 0);

  /// Checks if key landmarks for the specific exercise have sufficient confidence.
  bool hasExerciseConfidence(String exerciseType, [double minConfidence = 0.35]) {
    final lower = exerciseType.toLowerCase();
    if (lower.contains('pushup') || lower.contains('dip')) {
      final leftArm = leftShoulder.likelihood >= minConfidence &&
          leftElbow.likelihood >= minConfidence;
      final rightArm = rightShoulder.likelihood >= minConfidence &&
          rightElbow.likelihood >= minConfidence;
      return leftArm || rightArm;
    } else if (lower.contains('squat') || lower.contains('lunge')) {
      final leftLeg = leftHip.likelihood >= minConfidence &&
          leftKnee.likelihood >= minConfidence;
      final rightLeg = rightHip.likelihood >= minConfidence &&
          rightKnee.likelihood >= minConfidence;
      return leftLeg || rightLeg;
    } else if (lower.contains('plank')) {
      final leftCore = leftShoulder.likelihood >= minConfidence &&
          leftHip.likelihood >= minConfidence;
      final rightCore = rightShoulder.likelihood >= minConfidence &&
          rightHip.likelihood >= minConfidence;
      return leftCore || rightCore;
    }
    // Default: at least shoulder and hip visible on either side
    return (leftShoulder.likelihood >= minConfidence && leftHip.likelihood >= minConfidence) ||
        (rightShoulder.likelihood >= minConfidence && rightHip.likelihood >= minConfidence);
  }

  /// General confidence across core body landmarks (excluding facial points)
  bool hasGoodConfidence([double minConfidence = 0.4]) {
    if (landmarks.isEmpty) {
      return false;
    }
    final coreTypes = [
      mlkit.PoseLandmarkType.leftShoulder,
      mlkit.PoseLandmarkType.rightShoulder,
      mlkit.PoseLandmarkType.leftElbow,
      mlkit.PoseLandmarkType.rightElbow,
      mlkit.PoseLandmarkType.leftHip,
      mlkit.PoseLandmarkType.rightHip,
      mlkit.PoseLandmarkType.leftKnee,
      mlkit.PoseLandmarkType.rightKnee,
    ];

    double total = 0.0;
    int count = 0;
    for (final t in coreTypes) {
      final lm = landmarks[t];
      if (lm != null) {
        total += lm.likelihood;
        count++;
      }
    }
    if (count == 0) {
      return false;
    }
    return (total / count) >= minConfidence;
  }
}
