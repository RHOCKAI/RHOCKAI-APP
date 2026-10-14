import 'dart:math' as math;
import '../../features/camera_ai/analysis/angle_calculator.dart';
import '../../features/camera_ai/pose/pose_landmark_model.dart';

/// 📐 Pose Feature Extractor
///
/// Computes a fixed-dimension (18D) biomechanical kinematic feature vector
/// from 2D smoothed pose landmarks:
/// - 9 Joint angles (Left/Right Elbow, Shoulder, Hip, Knee + Spine alignment)
/// - 9 Joint angular velocities (time-normalized deg/s)
///
/// Ensures all values are finite, normalized, and NaN-free for TFLite inference.
class PoseFeatureExtractor {
  static const int featureDim = 18;
  static const int angleCount = 9;

  List<double>? _previousAngles;
  DateTime? _previousTimestamp;

  /// Extracts an 18-element feature vector from the given [pose].
  List<double> extractFeatures(PoseLandmarks pose, [DateTime? timestamp]) {
    final now = timestamp ?? DateTime.now();

    // 1. Compute 9 current joint angles (in degrees, bounded 0 - 180)
    final angles = List<double>.filled(angleCount, 0.0);

    // Elbows
    angles[0] = _safeAngle(AngleCalculator.getElbowAngle(pose, leftSide: true), fallback: 160.0);
    angles[1] = _safeAngle(AngleCalculator.getElbowAngle(pose, leftSide: false), fallback: 160.0);

    // Shoulders
    angles[2] = _safeAngle(
      AngleCalculator.calculate2DAngle(pose.leftElbow, pose.leftShoulder, pose.leftHip),
      fallback: 90.0,
    );
    angles[3] = _safeAngle(
      AngleCalculator.calculate2DAngle(pose.rightElbow, pose.rightShoulder, pose.rightHip),
      fallback: 90.0,
    );

    // Hips
    angles[4] = _safeAngle(AngleCalculator.getHipAngle(pose, leftSide: true), fallback: 180.0);
    angles[5] = _safeAngle(AngleCalculator.getHipAngle(pose, leftSide: false), fallback: 180.0);

    // Knees
    angles[6] = _safeAngle(AngleCalculator.getKneeAngle(pose, leftSide: true), fallback: 170.0);
    angles[7] = _safeAngle(AngleCalculator.getKneeAngle(pose, leftSide: false), fallback: 170.0);

    // Spine / Trunk Alignment
    final spineAngle = _calculateSpineAngle(pose);
    angles[8] = _safeAngle(spineAngle, fallback: 180.0);

    // 2. Compute 9 angular velocities
    final velocities = List<double>.filled(angleCount, 0.0);
    if (_previousAngles != null && _previousTimestamp != null) {
      final double dtSeconds = math.max(
        0.016, // Min 16ms to avoid division by near-zero
        now.difference(_previousTimestamp!).inMilliseconds / 1000.0,
      );

      for (int i = 0; i < angleCount; i++) {
        final delta = angles[i] - _previousAngles![i];
        final vel = delta / dtSeconds; // degrees per second
        velocities[i] = vel.clamp(-360.0, 360.0) / 360.0; // Normalized to [-1.0, 1.0]
      }
    }

    _previousAngles = List<double>.from(angles);
    _previousTimestamp = now;

    // 3. Assemble normalized 18-element feature vector
    // Angles normalized to [0.0, 1.0] (divided by 180.0)
    final features = List<double>.filled(featureDim, 0.0);
    for (int i = 0; i < angleCount; i++) {
      features[i] = (angles[i] / 180.0).clamp(0.0, 1.0);
      features[angleCount + i] = velocities[i];
    }

    return features;
  }

  /// Calculates trunk angle relative to vertical
  double _calculateSpineAngle(PoseLandmarks pose) {
    final leftShoulder = pose.leftShoulder;
    final rightShoulder = pose.rightShoulder;
    final leftHip = pose.leftHip;
    final rightHip = pose.rightHip;

    if (!leftShoulder.isUsable() || !leftHip.isUsable()) {
      return double.nan;
    }

    final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2.0;
    final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2.0;
    final midHipX = (leftHip.x + rightHip.x) / 2.0;
    final midHipY = (leftHip.y + rightHip.y) / 2.0;

    final dx = midShoulderX - midHipX;
    final dy = midShoulderY - midHipY;
    final rad = math.atan2(dx.abs(), dy.abs());
    return rad * 180.0 / math.pi;
  }

  /// Sanitizes angles against NaN, infinity, and missing landmark fallbacks
  double _safeAngle(double val, {required double fallback}) {
    if (val.isNaN || !val.isFinite) {
      return fallback;
    }
    return val.clamp(0.0, 180.0);
  }

  /// Reset velocity history on exercise switch or pause
  void reset() {
    _previousAngles = null;
    _previousTimestamp = null;
  }
}
