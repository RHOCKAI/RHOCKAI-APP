import '../pose/pose_landmark_model.dart';
import 'angle_calculator.dart';

/// 🧠 Exercise Classifier
/// 
/// Uses heuristic pattern matching to automatically identify the 
/// exercise being performed based on pose geometry.
class ExerciseClassifier {
  
  /// Detect the most likely exercise type
  static String? detectExercise(PoseLandmarks pose) {
    // 1. Check for Plank (Horizontal body, minimal joint movement)
    if (_isPlankPattern(pose)) {
      return 'plank';
    }
    
    // 2. Check for Push-up (Horizontal body, arm movement)
    if (_isPushupPattern(pose)) {
      return 'pushup';
    }
    
    // 3. Check for Squat (Vertical body, leg movement)
    if (_isSquatPattern(pose)) {
      return 'squat';
    }
    
    return null;
  }

  static bool _isPlankPattern(PoseLandmarks pose) {
    final hipAngle = AngleCalculator.getHipAngle(pose);
    final shoulderY = (pose.leftShoulder.y + pose.rightShoulder.y) / 2;
    final ankleY = (pose.leftAnkle.y + pose.rightAnkle.y) / 2;
    
    // Body is horizontal (shoulders and ankles on similar Y levels)
    // and relatively straight
    final isHorizontal = (shoulderY - ankleY).abs() < 0.3;
    final isStraight = (hipAngle - 180).abs() < 20;
    
    return isHorizontal && isStraight;
  }

  static bool _isPushupPattern(PoseLandmarks pose) {
    final shoulderY = (pose.leftShoulder.y + pose.rightShoulder.y) / 2;
    final ankleY = (pose.leftAnkle.y + pose.rightAnkle.y) / 2;
    
    // Horizontal body but checking for arm flexion
    final isHorizontal = (shoulderY - ankleY).abs() < 0.4;
    final elbowAngle = AngleCalculator.getAverageElbowAngle(pose);
    
    return isHorizontal && (elbowAngle < 150); // Arms are bent/bending
  }

  static bool _isSquatPattern(PoseLandmarks pose) {
    final shoulderY = (pose.leftShoulder.y + pose.rightShoulder.y) / 2;
    final ankleY = (pose.leftAnkle.y + pose.rightAnkle.y) / 2;
    
    // Vertical body (shoulders significantly above ankles)
    final isVertical = shoulderY < ankleY - 0.4;
    final kneeAngle = AngleCalculator.getAverageKneeAngle(pose);
    
    return isVertical && (kneeAngle < 160); // Legs are bent/bending
  }
}
