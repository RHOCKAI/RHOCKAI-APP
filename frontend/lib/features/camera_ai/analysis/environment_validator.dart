import 'dart:typed_data';
import 'package:camera/camera.dart';
import '../pose/pose_landmark_model.dart';
import '../../../core/constants/exercises.dart';

/// 💡 Environment Validator
/// 
/// Provides feedback on lighting conditions and user positioning
/// relative to the camera to optimize AI accuracy.
class EnvironmentValidator {
  
  /// Check lighting brightness using simple YUV luminance analysis
  static double calculateLuminance(CameraImage image) {
    if (image.format.group != ImageFormatGroup.nv21 && 
        image.format.group != ImageFormatGroup.yuv420) {
      return 1.0; // Assume okay for non-YUV formats (iOS)
    }
    
    // The first plane is usually the Y-plane (luminance)
    final Uint8List bytes = image.planes[0].bytes;
    int total = 0;
    
    // Sample every 100th pixel for performance
    for (int i = 0; i < bytes.length; i += 100) {
      total += bytes[i];
    }
    
    return total / (bytes.length / 100); // 0-255 scale
  }

  /// Verify user is at a good distance and fully in frame
  static String? checkPositioning(PoseLandmarks? pose) {
    if (pose == null) {
      return 'Stand in frame';
    }
    
    // Check if critical landmarks are missing or low confidence
    if (!pose.hasGoodConfidence(ExerciseThresholds.minLandmarkConfidence)) {
      return 'Lighting too dark or blocked view';
    }
    
    // Check height in frame (should be ~60-80% of frame height)
    final noseY = pose.nose.y;
    final ankleY = (pose.leftAnkle.y + pose.rightAnkle.y) / 2;
    final heightInFrame = (ankleY - noseY).abs();
    
    if (heightInFrame < 0.4) {
      return 'Come closer to camera';
    }
    if (heightInFrame > 0.9) {
      return 'Step back a bit';
    }
    
    // Check lateral centering
    final avgX = (pose.leftShoulder.x + pose.rightShoulder.x) / 2;
    if (avgX < 0.3) {
      return 'Move to your right';
    }
    if (avgX > 0.7) {
      return 'Move to your left';
    }
    
    return null; // Position is good
  }

  /// Combined status for UI
  static EnvironmentStatus validate(CameraImage image, PoseLandmarks? pose) {
    final luminance = calculateLuminance(image);
    final posIssue = checkPositioning(pose);
    
    if (luminance < 40) {
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
