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

  bool isUsable([double minConfidence = 0.25]) =>
      x.isFinite &&
      y.isFinite &&
      likelihood.isFinite &&
      likelihood >= minConfidence &&
      likelihood <= 1.0;

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

  /// Checks that every landmark needed by the exercise angle checks is visible.
  bool hasExerciseConfidence(
    String exerciseType, [
    double minConfidence = 0.35,
  ]) {
    final lower = exerciseType
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');

    bool visible(PoseLandmark a, PoseLandmark b, PoseLandmark c) =>
        a.isUsable(minConfidence) &&
        b.isUsable(minConfidence) &&
        c.isUsable(minConfidence);

    final leftCore = visible(leftShoulder, leftHip, leftKnee);
    final rightCore = visible(rightShoulder, rightHip, rightKnee);

    if (lower.contains('pushup') || lower.contains('dip')) {
      final hasArmAngle = visible(leftShoulder, leftElbow, leftWrist) ||
          visible(rightShoulder, rightElbow, rightWrist);
      return (leftCore || rightCore) && hasArmAngle;
    }
    if (lower.contains('squat') || lower.contains('lunge')) {
      final hasLegAngle = visible(leftHip, leftKnee, leftAnkle) ||
          visible(rightHip, rightKnee, rightAnkle);
      return hasLegAngle && (leftCore || rightCore);
    }
    if (lower.contains('plank')) {
      return leftCore || rightCore;
    }
    return false;
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
