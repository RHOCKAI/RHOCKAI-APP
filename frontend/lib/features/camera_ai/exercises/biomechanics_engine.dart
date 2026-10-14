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
  /// Returns a projected 2D angle; NaN signals missing or degenerate geometry.
  static double calculateAngle(Offset a, Offset b, Offset c) {
    if (!a.dx.isFinite ||
        !a.dy.isFinite ||
        !b.dx.isFinite ||
        !b.dy.isFinite ||
        !c.dx.isFinite ||
        !c.dy.isFinite) {
      return double.nan;
    }

    final abX = a.dx - b.dx;
    final abY = a.dy - b.dy;
    final cbX = c.dx - b.dx;
    final cbY = c.dy - b.dy;
    final abLength = sqrt(abX * abX + abY * abY);
    final cbLength = sqrt(cbX * cbX + cbY * cbY);
    if (abLength < 1e-4 || cbLength < 1e-4) return double.nan;

    final cosine =
        ((abX * cbX + abY * cbY) / (abLength * cbLength)).clamp(-1.0, 1.0);
    return acos(cosine) * 180.0 / pi;
  }

  /// Calculate angle from landmarks
  static double calculateAngleFromLandmarks(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    if (!a.isUsable() || !b.isUsable() || !c.isUsable()) {
      return double.nan;
    }
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
        final angle = calculateAngleFromLandmarks(a, b, c);
        if (angle.isFinite) angles[entry.key] = angle;
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
  static double calculateAlignmentScore(
    List<Offset> points, {
    double maxDeviation = 0.05,
  }) {
    if (points.length < 3 ||
        !maxDeviation.isFinite ||
        maxDeviation <= 0 ||
        points.any((point) => !point.dx.isFinite || !point.dy.isFinite)) {
      return 0.0;
    }

    // Measure perpendicular distance to the line joining the outer points.
    // This also handles near-vertical bodies without a slope singularity.
    final start = points.first;
    final end = points.last;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length < 1e-4) return 0.0;

    var totalDeviation = 0.0;
    for (final point in points) {
      final deviation =
          ((point.dx - start.dx) * dy - (point.dy - start.dy) * dx).abs() /
              length;
      totalDeviation += deviation;
    }
    final averageDeviation = totalDeviation / points.length;
    return (1.0 - averageDeviation / maxDeviation).clamp(0.0, 1.0);
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
    if (!leftAngle.isFinite || !rightAngle.isFinite) return 0.0;
    final difference = (leftAngle - rightAngle).abs();
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
    final leftVisible = landmarks.leftShoulder.isUsable() &&
        landmarks.leftHip.isUsable() &&
        landmarks.leftAnkle.isUsable();
    final rightVisible = landmarks.rightShoulder.isUsable() &&
        landmarks.rightHip.isUsable() &&
        landmarks.rightAnkle.isUsable();
    final leftAngle = leftVisible
        ? calculateAngleFromLandmarks(
            landmarks.leftShoulder, landmarks.leftHip, landmarks.leftAnkle)
        : double.nan;
    final rightAngle = rightVisible
        ? calculateAngleFromLandmarks(
            landmarks.rightShoulder, landmarks.rightHip, landmarks.rightAnkle)
        : double.nan;
    final angle = leftAngle.isFinite && rightAngle.isFinite
        ? (leftAngle + rightAngle) / 2
        : leftAngle.isFinite
            ? leftAngle
            : rightAngle;
    return angle.isFinite && (180 - angle).abs() < maxSag;
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
