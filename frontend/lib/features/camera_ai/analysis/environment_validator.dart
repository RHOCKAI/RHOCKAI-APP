import 'dart:typed_data';
import 'package:camera/camera.dart';
import '../pose/pose_landmark_model.dart';

/// 💡 Environment Validator
///
/// Provides feedback on lighting conditions and user positioning
/// relative to the camera to optimize AI accuracy.
class EnvironmentValidator {
  /// Check lighting brightness using simple YUV luminance analysis
  static double calculateLuminance(CameraImage image) {
    if (image.format.group != ImageFormatGroup.nv21 &&
        image.format.group != ImageFormatGroup.yuv420) {
      return 120.0; // Assume okay for non-YUV formats (iOS)
    }

    if (image.planes.isEmpty) {
      return 120.0;
    }

    final Uint8List bytes = image.planes[0].bytes;
    if (bytes.isEmpty) {
      return 120.0;
    }

    int total = 0;
    int sampled = 0;

    // Sample every 200th pixel for rapid performance
    for (int i = 0; i < bytes.length; i += 200) {
      total += bytes[i];
      sampled++;
    }

    if (sampled == 0) {
      return 120.0;
    }
    return total / sampled; // 0-255 scale
  }

  /// Verify user is in frame with normalized coordinates
  static String? checkPositioning(CameraImage image, PoseLandmarks? pose, {String? exerciseType}) {
    if (pose == null) {
      return 'Step into the camera frame';
    }

    final isFloor = exerciseType != null &&
        (exerciseType.toLowerCase().contains('pushup') ||
            exerciseType.toLowerCase().contains('plank') ||
            exerciseType.toLowerCase().contains('bridge'));

    if (isFloor) {
      // For pushups/planks, user is on the floor
      final hasArm = pose.leftShoulder.likelihood > 0.25 || pose.rightShoulder.likelihood > 0.25;
      final hasCore = pose.leftHip.likelihood > 0.25 || pose.rightHip.likelihood > 0.25;
      if (!hasArm && !hasCore) {
        return 'Position your mat in camera view';
      }
      return null;
    }

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    if (imgW <= 0 || imgH <= 0) {
      return null;
    }

    // Normalize coordinates
    final avgX = ((pose.leftShoulder.x + pose.rightShoulder.x) / 2) / imgW;

    if (avgX < 0.1) {
      return 'Move towards center';
    }
    if (avgX > 0.9) {
      return 'Move towards center';
    }

    return null; // Position is good
  }

  /// Combined status for UI
  static EnvironmentStatus validate(CameraImage image, PoseLandmarks? pose, {String? exerciseType}) {
    final luminance = calculateLuminance(image);
    final posIssue = checkPositioning(image, pose, exerciseType: exerciseType);

    if (luminance < 30) {
      return EnvironmentStatus(isValid: false, message: 'Too dark! Turn on lights 💡');
    }

    if (posIssue != null) {
      return EnvironmentStatus(isValid: false, message: posIssue);
    }

    return EnvironmentStatus(isValid: true, message: 'Environment Ready ✅');
  }
}

class EnvironmentStatus {
  final bool isValid;
  final String message;

  EnvironmentStatus({required this.isValid, required this.message});
}
