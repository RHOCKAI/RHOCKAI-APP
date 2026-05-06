import 'dart:math' as math;
import '../pose/pose_landmark_model.dart';

class AngleCalculator {
  /// Calculate 3D angle between three points (in degrees)
  /// Uses X, Y, and Z for true spatial accuracy.
  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // Vector BA (from b to a)
    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final baZ = a.z - b.z;

    // Vector BC (from b to c)
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;
    final bcZ = c.z - b.z;

    // Dot product
    final dotProduct = (baX * bcX) + (baY * bcY) + (baZ * bcZ);

    // Magnitudes
    final magnitudeBA = math.sqrt((baX * baX) + (baY * baY) + (baZ * baZ));
    final magnitudeBC = math.sqrt((bcX * bcX) + (bcY * bcY) + (bcZ * bcZ));

    if (magnitudeBA == 0 || magnitudeBC == 0) {
      return 0.0;
    }

    // Angle in radians, then convert to degrees
    final cosineValue = (dotProduct / (magnitudeBA * magnitudeBC)).clamp(-1.0, 1.0);
    final angleRad = math.acos(cosineValue);
    
    return angleRad * 180 / math.pi;
  }

  /// Calculate elbow angle for push-ups (3D)
  static double getElbowAngle(PoseLandmarks pose, {bool leftSide = true}) {
    if (leftSide) {
      return calculateAngle(
        pose.leftShoulder,
        pose.leftElbow,
        pose.leftWrist,
      );
    } else {
      return calculateAngle(
        pose.rightShoulder,
        pose.rightElbow,
        pose.rightWrist,
      );
    }
  }

  /// Calculate average elbow angle from both sides
  static double getAverageElbowAngle(PoseLandmarks pose) {
    final leftAngle = getElbowAngle(pose, leftSide: true);
    final rightAngle = getElbowAngle(pose, leftSide: false);
    return (leftAngle + rightAngle) / 2;
  }

  /// Calculate knee angle for squats (3D)
  static double getKneeAngle(PoseLandmarks pose, {bool leftSide = true}) {
    if (leftSide) {
      return calculateAngle(
        pose.leftHip,
        pose.leftKnee,
        pose.leftAnkle,
      );
    } else {
      return calculateAngle(
        pose.rightHip,
        pose.rightKnee,
        pose.rightAnkle,
      );
    }
  }

  /// Calculate average knee angle from both sides
  static double getAverageKneeAngle(PoseLandmarks pose) {
    final leftAngle = getKneeAngle(pose, leftSide: true);
    final rightAngle = getKneeAngle(pose, leftSide: false);
    return (leftAngle + rightAngle) / 2;
  }

  /// Calculate hip angle for planks (3D)
  static double getHipAngle(PoseLandmarks pose, {bool leftSide = true}) {
    if (leftSide) {
      return calculateAngle(
        pose.leftShoulder,
        pose.leftHip,
        pose.leftKnee,
      );
    } else {
      return calculateAngle(
        pose.rightShoulder,
        pose.rightHip,
        pose.rightKnee,
      );
    }
  }

  /// Check if body is straight (used for plank detection)
  static bool isBodyStraight(PoseLandmarks pose, double tolerance) {
    final leftHipAngle = getHipAngle(pose, leftSide: true);
    final rightHipAngle = getHipAngle(pose, leftSide: false);

    // Body is straight if both hips are close to 180 degrees
    return (leftHipAngle - 180).abs() <= tolerance &&
        (rightHipAngle - 180).abs() <= tolerance;
  }

  /// Calculate 3D distance between two points
  static double calculateDistance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final dz = a.z - b.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}
