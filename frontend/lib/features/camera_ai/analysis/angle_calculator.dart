import 'dart:math' as math;
import '../pose/pose_landmark_model.dart';

/// Computes joint angles in the camera image plane.
///
/// These are projected 2D angles. Accuracy depends on a suitable camera view
/// and reliable landmarks; this is not a 3D biomechanical measurement.
class AngleCalculator {
  static const double minimumLikelihood = 0.25;

  static double calculate2DAngle(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    if (!a.isUsable(minimumLikelihood) ||
        !b.isUsable(minimumLikelihood) ||
        !c.isUsable(minimumLikelihood)) {
      return double.nan;
    }

    final baX = a.x - b.x;
    final baY = a.y - b.y;
    final bcX = c.x - b.x;
    final bcY = c.y - b.y;
    final magnitudeBA = math.sqrt(baX * baX + baY * baY);
    final magnitudeBC = math.sqrt(bcX * bcX + bcY * bcY);
    if (magnitudeBA < 1e-4 || magnitudeBC < 1e-4) return double.nan;

    final dotProduct = baX * bcX + baY * bcY;
    final cosine = (dotProduct / (magnitudeBA * magnitudeBC)).clamp(-1.0, 1.0);
    return math.acos(cosine) * 180.0 / math.pi;
  }

  static double calculateAngle(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) => calculate2DAngle(a, b, c);

  static double getElbowAngle(PoseLandmarks pose, {bool leftSide = true}) =>
      leftSide
      ? calculate2DAngle(pose.leftShoulder, pose.leftElbow, pose.leftWrist)
      : calculate2DAngle(pose.rightShoulder, pose.rightElbow, pose.rightWrist);

  static double getAverageElbowAngle(PoseLandmarks pose) => _selectAngle(
    getElbowAngle(pose, leftSide: true),
    getElbowAngle(pose, leftSide: false),
    _confidence([pose.leftShoulder, pose.leftElbow, pose.leftWrist]),
    _confidence([pose.rightShoulder, pose.rightElbow, pose.rightWrist]),
  );

  static double getKneeAngle(PoseLandmarks pose, {bool leftSide = true}) =>
      leftSide
      ? calculate2DAngle(pose.leftHip, pose.leftKnee, pose.leftAnkle)
      : calculate2DAngle(pose.rightHip, pose.rightKnee, pose.rightAnkle);

  static double getAverageKneeAngle(PoseLandmarks pose) => _selectAngle(
    getKneeAngle(pose, leftSide: true),
    getKneeAngle(pose, leftSide: false),
    _confidence([pose.leftHip, pose.leftKnee, pose.leftAnkle]),
    _confidence([pose.rightHip, pose.rightKnee, pose.rightAnkle]),
  );

  static double getHipAngle(PoseLandmarks pose, {bool? leftSide}) {
    if (leftSide != null) {
      return leftSide
          ? calculate2DAngle(pose.leftShoulder, pose.leftHip, pose.leftKnee)
          : calculate2DAngle(pose.rightShoulder, pose.rightHip, pose.rightKnee);
    }
    return _selectAngle(
      calculate2DAngle(pose.leftShoulder, pose.leftHip, pose.leftKnee),
      calculate2DAngle(pose.rightShoulder, pose.rightHip, pose.rightKnee),
      _confidence([pose.leftShoulder, pose.leftHip, pose.leftKnee]),
      _confidence([pose.rightShoulder, pose.rightHip, pose.rightKnee]),
    );
  }

  static double _confidence(List<PoseLandmark> points) {
    if (points.any((point) => !point.isUsable(minimumLikelihood))) return -1;
    return points.map((point) => point.likelihood).reduce((a, b) => a + b) /
        points.length;
  }

  static double _selectAngle(
    double left,
    double right,
    double leftConf,
    double rightConf,
  ) {
    final leftValid = left.isFinite;
    final rightValid = right.isFinite;
    if (leftValid && rightValid) {
      if ((leftConf - rightConf).abs() >= 0.2) {
        return leftConf > rightConf ? left : right;
      }
      return (left + right) / 2;
    }
    if (leftValid) return left;
    if (rightValid) return right;
    return double.nan;
  }

  static bool isBodyStraight(PoseLandmarks pose, double tolerance) {
    final hipAngle = getHipAngle(pose);
    return hipAngle.isFinite && (hipAngle - 180).abs() <= tolerance;
  }

  static double calculateDistance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
