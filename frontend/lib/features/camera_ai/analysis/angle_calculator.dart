import 'dart:math' as math;
import '../pose/pose_landmark_model.dart';

class AngleCalculator {
  /// Calculate robust 2D angle between three points (A -> B -> C) in degrees.
  /// B is the vertex/joint (e.g., elbow or knee).
  ///
  /// Uses pixel coordinates on the camera projection plane.
  /// 2D plane angles are invariant to ML Kit's noisy uncalibrated pseudo-depth Z
  /// and match visual biomechanics with true fidelity.
  static double calculate2DAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // If any point is uninitialized or missing (0,0 with 0 likelihood)
    if ((a.x == 0 && a.y == 0 && a.likelihood == 0) ||
        (b.x == 0 && b.y == 0 && b.likelihood == 0) ||
        (c.x == 0 && c.y == 0 && c.likelihood == 0)) {
      return 180.0; // Neutral default for unobserved limbs
    }

    final baX = a.x - b.x;
    final baY = a.y - b.y;

    final bcX = c.x - b.x;
    final bcY = c.y - b.y;

    final dotProduct = (baX * bcX) + (baY * bcY);
    final magnitudeBA = math.sqrt((baX * baX) + (baY * baY));
    final magnitudeBC = math.sqrt((bcX * bcX) + (bcY * bcY));

    if (magnitudeBA < 1e-4 || magnitudeBC < 1e-4) {
      return 180.0;
    }

    final cosineValue = (dotProduct / (magnitudeBA * magnitudeBC)).clamp(-1.0, 1.0);
    return math.acos(cosineValue) * 180.0 / math.pi;
  }

  /// Backward-compatible alias for 3D/2D angle calculation.
  /// Calculates joint angle with robust 2D projection.
  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    return calculate2DAngle(a, b, c);
  }

  /// Calculate elbow angle for push-ups.
  /// Vertex is Elbow, arms are Shoulder and Wrist.
  static double getElbowAngle(PoseLandmarks pose, {bool leftSide = true}) {
    if (leftSide) {
      return calculate2DAngle(
        pose.leftShoulder,
        pose.leftElbow,
        pose.leftWrist,
      );
    } else {
      return calculate2DAngle(
        pose.rightShoulder,
        pose.rightElbow,
        pose.rightWrist,
      );
    }
  }

  /// Intelligently calculate elbow angle:
  /// - Automatically selects the side facing the camera / with higher confidence.
  /// - If both arms are clearly visible (e.g. front view), averages both sides.
  /// - If user is in side/angled profile (standard pushup pose), uses the visible arm
  ///   without being corrupted by the occluded arm.
  static double getAverageElbowAngle(PoseLandmarks pose) {
    final leftValid = pose.leftShoulder.likelihood > 0.25 &&
        pose.leftElbow.likelihood > 0.25;
    final rightValid = pose.rightShoulder.likelihood > 0.25 &&
        pose.rightElbow.likelihood > 0.25;

    final leftConf = (pose.leftShoulder.likelihood +
            pose.leftElbow.likelihood +
            pose.leftWrist.likelihood) /
        3;
    final rightConf = (pose.rightShoulder.likelihood +
            pose.rightElbow.likelihood +
            pose.rightWrist.likelihood) /
        3;

    if (leftValid && rightValid) {
      // If one side has significantly higher confidence, prioritize it (side profile)
      if (leftConf - rightConf > 0.25) {
        return getElbowAngle(pose, leftSide: true);
      } else if (rightConf - leftConf > 0.25) {
        return getElbowAngle(pose, leftSide: false);
      }
      // Both sides clear: average them
      final leftAngle = getElbowAngle(pose, leftSide: true);
      final rightAngle = getElbowAngle(pose, leftSide: false);
      return (leftAngle + rightAngle) / 2;
    } else if (leftValid) {
      return getElbowAngle(pose, leftSide: true);
    } else if (rightValid) {
      return getElbowAngle(pose, leftSide: false);
    }

    // Fallback: pick whichever has slightly better confidence
    return leftConf >= rightConf
        ? getElbowAngle(pose, leftSide: true)
        : getElbowAngle(pose, leftSide: false);
  }

  /// Calculate knee angle for squats.
  /// Vertex is Knee, limbs are Hip and Ankle.
  static double getKneeAngle(PoseLandmarks pose, {bool leftSide = true}) {
    if (leftSide) {
      return calculate2DAngle(
        pose.leftHip,
        pose.leftKnee,
        pose.leftAnkle,
      );
    } else {
      return calculate2DAngle(
        pose.rightHip,
        pose.rightKnee,
        pose.rightAnkle,
      );
    }
  }

  /// Intelligently calculate knee angle for squats:
  /// Uses the most visible leg, or averages if both are equally clear.
  static double getAverageKneeAngle(PoseLandmarks pose) {
    final leftValid = pose.leftHip.likelihood > 0.25 &&
        pose.leftKnee.likelihood > 0.25;
    final rightValid = pose.rightHip.likelihood > 0.25 &&
        pose.rightKnee.likelihood > 0.25;

    final leftConf = (pose.leftHip.likelihood +
            pose.leftKnee.likelihood +
            pose.leftAnkle.likelihood) /
        3;
    final rightConf = (pose.rightHip.likelihood +
            pose.rightKnee.likelihood +
            pose.rightAnkle.likelihood) /
        3;

    if (leftValid && rightValid) {
      if (leftConf - rightConf > 0.25) {
        return getKneeAngle(pose, leftSide: true);
      } else if (rightConf - leftConf > 0.25) {
        return getKneeAngle(pose, leftSide: false);
      }
      final leftAngle = getKneeAngle(pose, leftSide: true);
      final rightAngle = getKneeAngle(pose, leftSide: false);
      return (leftAngle + rightAngle) / 2;
    } else if (leftValid) {
      return getKneeAngle(pose, leftSide: true);
    } else if (rightValid) {
      return getKneeAngle(pose, leftSide: false);
    }

    return leftConf >= rightConf
        ? getKneeAngle(pose, leftSide: true)
        : getKneeAngle(pose, leftSide: false);
  }

  /// Calculate hip angle for planks and torso alignment.
  /// Vertex is Hip, endpoints are Shoulder and Knee.
  static double getHipAngle(PoseLandmarks pose, {bool? leftSide}) {
    if (leftSide != null) {
      return leftSide
          ? calculate2DAngle(pose.leftShoulder, pose.leftHip, pose.leftKnee)
          : calculate2DAngle(pose.rightShoulder, pose.rightHip, pose.rightKnee);
    }

    // Auto-detect best side
    final leftConf = (pose.leftShoulder.likelihood +
            pose.leftHip.likelihood +
            pose.leftKnee.likelihood) /
        3;
    final rightConf = (pose.rightShoulder.likelihood +
            pose.rightHip.likelihood +
            pose.rightKnee.likelihood) /
        3;

    if (leftConf > 0.25 && rightConf > 0.25) {
      final leftAngle = calculate2DAngle(pose.leftShoulder, pose.leftHip, pose.leftKnee);
      final rightAngle = calculate2DAngle(pose.rightShoulder, pose.rightHip, pose.rightKnee);
      return (leftAngle + rightAngle) / 2;
    } else if (leftConf > 0.25) {
      return calculate2DAngle(pose.leftShoulder, pose.leftHip, pose.leftKnee);
    } else if (rightConf > 0.25) {
      return calculate2DAngle(pose.rightShoulder, pose.rightHip, pose.rightKnee);
    }

    return leftConf >= rightConf
        ? calculate2DAngle(pose.leftShoulder, pose.leftHip, pose.leftKnee)
        : calculate2DAngle(pose.rightShoulder, pose.rightHip, pose.rightKnee);
  }

  /// Check if body is straight (used for plank detection)
  static bool isBodyStraight(PoseLandmarks pose, double tolerance) {
    final hipAngle = getHipAngle(pose);
    return (hipAngle - 180).abs() <= tolerance;
  }

  /// Calculate 2D distance between two points in image pixels
  static double calculateDistance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
