import 'dart:math';
import 'dart:ui' show Offset;
import '../pose/pose_landmark_model.dart';
import 'exercise_model.dart';

/// Biomechanics engine for pose analysis
///
/// Provides mathematical functions for:
/// - Joint angle calculations
/// - Distance measurements
/// - Velocity tracking
/// - Body alignment analysis
/// - Symmetry detection
class BiomechanicsEngine {
  /// Calculate angle between three points (in degrees)
  ///
  /// Formula:
  /// angle = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x)
  ///
  /// Returns angle in range [0, 180] degrees
  static double calculateAngle(Offset a, Offset b, Offset c) {
    final radians =
        atan2(c.dy - b.dy, c.dx - b.dx) - atan2(a.dy - b.dy, a.dx - b.dx);
    double angle = radians.abs() * 180.0 / pi;

    // Normalize to [0, 180]
    if (angle > 180) {
      angle = 360 - angle;
    }

    return angle;
  }

  /// Calculate angle from landmarks
  static double calculateAngleFromLandmarks(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    return calculateAngle(a.position, b.position, c.position);
  }

  /// Calculate all angles defined in exercise
  static Map<String, double> calculateAngles(
    PoseLandmarks landmarks,
    Map<String, AngleDefinition> angleDefinitions,
  ) {
    final angles = <String, double>{};

    for (final entry in angleDefinitions.entries) {
      final angleDef = entry.value;
      final a = landmarks.getLandmark(angleDef.pointA);
      final b = landmarks.getLandmark(angleDef.vertex);
      final c = landmarks.getLandmark(angleDef.pointC);

      if (a != null && b != null && c != null) {
        angles[entry.key] = calculateAngleFromLandmarks(a, b, c);
      }
    }

    return angles;
  }

  /// Calculate distance between two points
  static double calculateDistance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
  }

  /// Calculate distance between two landmarks
  static double calculateLandmarkDistance(PoseLandmark a, PoseLandmark b) {
    return calculateDistance(a.position, b.position);
  }

  /// Check if point is vertical (within tolerance)
  /// Used for checking upright posture
  static bool isVertical(Offset top, Offset bottom, {double tolerance = 10.0}) {
    final angle =
        atan2(bottom.dy - top.dy, bottom.dx - top.dx).abs() * 180 / pi;
    return (angle - 90).abs() < tolerance;
  }

  /// Check if three points are aligned (collinear)
  static bool isAligned(Offset a, Offset b, Offset c,
      {double tolerance = 10.0}) {
    final angle = calculateAngle(a, b, c);
    return (angle - 180).abs() < tolerance;
  }

  /// Calculate body alignment score (0-1)
  /// For checking straight back, etc.
  static double calculateAlignmentScore(List<Offset> points,
      {double maxDeviation = 0.05}) {
    if (points.length < 3) {
      return 1.0;
    }

    // Fit line through points and calculate deviation
    double totalDeviation = 0.0;

    // Simple linear regression
    double sumX = 0, sumY = 0;
    for (final p in points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    final meanX = sumX / points.length;
    final meanY = sumY / points.length;

    double numerator = 0, denominator = 0;
    for (final p in points) {
      numerator += (p.dx - meanX) * (p.dy - meanY);
      denominator += (p.dx - meanX) * (p.dx - meanX);
    }

    if (denominator == 0) {
      return 1.0;
    }

    final slope = numerator / denominator;
    final intercept = meanY - slope * meanX;

    // Calculate deviation from fitted line
    for (final p in points) {
      final expectedY = slope * p.dx + intercept;
      final deviation = (p.dy - expectedY).abs();
      totalDeviation += deviation;
    }

    final avgDeviation = totalDeviation / points.length;
    final score = 1.0 - (avgDeviation / maxDeviation).clamp(0.0, 1.0);

    return score;
  }

  /// Check if knees are past toes (squat form check)
  static bool kneesNotPastToes(PoseLandmarks landmarks,
      {double threshold = 0.05}) {
    final leftKnee = landmarks.leftKnee;
    final rightKnee = landmarks.rightKnee;
    final leftAnkle = landmarks.leftAnkle;
    final rightAnkle = landmarks.rightAnkle;

    // Check left side
    final leftKneeFront =
        leftKnee.position.dx > leftAnkle.position.dx + threshold;
    // Check right side
    final rightKneeFront =
        rightKnee.position.dx > rightAnkle.position.dx + threshold;

    return !leftKneeFront && !rightKneeFront;
  }

  /// Calculate symmetry score between left and right angles
  static double calculateSymmetry(double leftAngle, double rightAngle) {
    final difference = (leftAngle - rightAngle).abs();

    // Perfect symmetry = 1.0, 20+ degrees difference = 0.0
    return (1.0 - (difference / 20.0)).clamp(0.0, 1.0);
  }

  /// Detect if body is in horizontal position (planks, push-ups)
  static bool isHorizontal(PoseLandmarks landmarks, {double tolerance = 20.0}) {
    final shoulder = landmarks.leftShoulder;
    final hip = landmarks.leftHip;

    final verticalDiff = (shoulder.position.dy - hip.position.dy).abs();
    final horizontalDiff = (shoulder.position.dx - hip.position.dx).abs();

    final angle = atan2(verticalDiff, horizontalDiff) * 180 / pi;
    return angle < tolerance;
  }

  /// Calculate hip height relative to screen (0 = bottom, 1 = top)
  static double getHipHeight(PoseLandmarks landmarks) {
    final leftHip = landmarks.leftHip;
    final rightHip = landmarks.rightHip;
    final avgY = (leftHip.position.dy + rightHip.position.dy) / 2;

    return 1.0 - avgY; // Invert because y increases downward
  }

  /// Detect if person is standing upright
  static bool isStanding(PoseLandmarks landmarks) {
    final hipHeight = getHipHeight(landmarks);
    return hipHeight > 0.5; // Hip above midpoint
  }

  /// Calculate velocity of a landmark between frames
  static double calculateVelocity(
    Offset currentPosition,
    Offset previousPosition,
    Duration timeDelta,
  ) {
    final distance = calculateDistance(currentPosition, previousPosition);
    final seconds = timeDelta.inMilliseconds / 1000.0;
    return distance / seconds;
  }

  /// Detect if movement is too fast (tempo check)
  static bool isMovementTooFast(
    double velocity,
    double threshold,
  ) {
    return velocity > threshold;
  }

  /// Calculate range of motion percentage
  ///
  /// Example: Knee goes from 160° (straight) to 90° (bent)
  /// Actual: 160° to 100° = 60° movement out of 70° possible = 85.7%
  static double calculateRangeOfMotion({
    required double currentAngle,
    required double startAngle,
    required double targetAngle,
  }) {
    final possibleRange = (targetAngle - startAngle).abs();
    final achievedRange = (currentAngle - startAngle).abs();

    if (possibleRange == 0) {
      return 1.0;
    }

    return (achievedRange / possibleRange).clamp(0.0, 1.0);
  }

  /// Check if core is engaged (body straight from shoulder to ankle)
  static bool isCoreEngaged(PoseLandmarks landmarks, {double maxSag = 15.0}) {
    final shoulder = landmarks.leftShoulder.position;
    final hip = landmarks.leftHip.position;
    final ankle = landmarks.leftAnkle.position;

    final angle = calculateAngle(shoulder, hip, ankle);

    // Should be close to 180° (straight line)
    return (180 - angle).abs() < maxSag;
  }

  /// Calculate body COM (center of mass) approximation
  static Offset calculateCenterOfMass(PoseLandmarks landmarks) {
    // Simplified: average of hip and shoulder positions
    final leftShoulder = landmarks.leftShoulder.position;
    final rightShoulder = landmarks.rightShoulder.position;
    final leftHip = landmarks.leftHip.position;
    final rightHip = landmarks.rightHip.position;

    final avgX =
        (leftShoulder.dx + rightShoulder.dx + leftHip.dx + rightHip.dx) / 4;
    final avgY =
        (leftShoulder.dy + rightShoulder.dy + leftHip.dy + rightHip.dy) / 4;

    return Offset(avgX, avgY);
  }

  /// Check balance (COM over base of support)
  static bool isBalanced(PoseLandmarks landmarks, {double threshold = 0.1}) {
    final com = calculateCenterOfMass(landmarks);

    // Base of support: average of feet
    final leftFoot = landmarks.leftAnkle.position;
    final rightFoot = landmarks.rightAnkle.position;
    final baseCenter = Offset(
      (leftFoot.dx + rightFoot.dx) / 2,
      (leftFoot.dy + rightFoot.dy) / 2,
    );

    final distance = calculateDistance(com, baseCenter);
    return distance < threshold;
  }
}
