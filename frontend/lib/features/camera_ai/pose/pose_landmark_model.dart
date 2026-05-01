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

  bool hasGoodConfidence(double minConfidence) {
    if (landmarks.isEmpty) {
      return false;
    }
    double avgConfidence = 0.0;
    for (var l in landmarks.values) {
      avgConfidence += l.likelihood;
    }
    avgConfidence /= landmarks.length;
    return avgConfidence >= minConfidence;
  }
}
