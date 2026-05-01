import '../pose/pose_landmark_model.dart';
import 'exercise_model.dart';
import 'biomechanics_engine.dart';

/// Form scoring system - evaluates exercise form quality
/// 
/// Calculates:
/// - Overall accuracy (0-100)
/// - Individual criterion scores
/// - Feedback messages
/// - Form mistakes
class FormScorer {
  final ExerciseDefinition exercise;

  FormScorer(this.exercise);

  /// Evaluate form and generate score
  FormCheckResult evaluateForm(
    PoseLandmarks landmarks,
    Map<String, double> angles,
  ) {
    final criteriaResults = <CriterionResult>[];
    final failedCriteria = <String>[];
    final feedbackMessages = <String>[];
    
    double totalWeight = 0.0;
    double achievedScore = 0.0;
    
    // Evaluate each criterion
    for (final criterion in exercise.formCriteria) {
      final passed = criterion.checkFunction(angles, landmarks);
      
      criteriaResults.add(
        CriterionResult(
          criterionId: criterion.id,
          name: criterion.name,
          passed: passed,
          weight: criterion.weight,
        ),
      );
      
      totalWeight += criterion.weight;
      
      if (passed) {
        achievedScore += criterion.weight;
      } else {
        failedCriteria.add(criterion.id);
        if (criterion.feedbackMessage != null) {
          feedbackMessages.add(criterion.feedbackMessage!);
        }
      }
    }
    
    // Calculate percentage score
    final accuracy = totalWeight > 0 
        ? (achievedScore / totalWeight) * 100 
        : 100.0;
    
    final passedAll = failedCriteria.isEmpty;
    
    return FormCheckResult(
      accuracy: accuracy,
      criteriaResults: criteriaResults,
      failedCriteria: failedCriteria,
      feedbackMessages: feedbackMessages,
      passedAll: passedAll,
    );
  }

  /// Get feedback message for specific form issue
  static String getFeedbackMessage(String criterionId) {
    final messages = {
      'back_straight': 'Keep your back straight',
      'core_engaged': 'Engage your core',
      'knees_not_past_toes': 'Keep knees behind toes',
      'knee_alignment': 'Align your knees with toes',
      'depth': 'Go deeper for full range',
      'elbow_position': 'Keep elbows at 45°',
      'hip_alignment': 'Keep hips level',
      'shoulder_position': 'Shoulders back and down',
      'tempo': 'Control your movement speed',
      'balance': 'Maintain balance',
      'symmetry': 'Keep movements symmetrical',
    };
    
    return messages[criterionId] ?? 'Check your form';
  }
}

/// Common form check functions that can be reused
class FormCheckFunctions {
  /// Check if back is straight (for push-ups, planks)
  static bool backStraight(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    final shoulder = landmarks.leftShoulder.position;
    final hip = landmarks.leftHip.position;
    final ankle = landmarks.leftAnkle.position;
    
    final angle = BiomechanicsEngine.calculateAngle(shoulder, hip, ankle);
    
    // Should be close to 180° (straight line)
    return (180 - angle).abs() < 15;
  }

  /// Check if core is engaged
  static bool coreEngaged(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    return BiomechanicsEngine.isCoreEngaged(landmarks);
  }

  /// Check if knees don't pass toes (squats, lunges)
  static bool kneesNotPastToes(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    return BiomechanicsEngine.kneesNotPastToes(landmarks);
  }

  /// Check knee alignment (knees tracking over toes)
  static bool kneeAlignment(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    // Check if knees are in line with ankles (not caving inward)
    final leftKnee = landmarks.leftKnee.position;
    final leftAnkle = landmarks.leftAnkle.position;
    final rightKnee = landmarks.rightKnee.position;
    final rightAnkle = landmarks.rightAnkle.position;
    
    final leftDiff = (leftKnee.dx - leftAnkle.dx).abs();
    final rightDiff = (rightKnee.dx - rightAnkle.dx).abs();
    
    // Allow some tolerance
    return leftDiff < 0.1 && rightDiff < 0.1;
  }

  /// Check squat depth (parallel or below)
  static bool squatDepth(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    final kneeAngle = angles['knee'];
    if (kneeAngle == null) {
      return false;
    }
    
    // Should reach at least 90° (parallel)
    return kneeAngle <= 100;
  }

  /// Check elbow position for push-ups (45° from body)
  static bool elbowPosition(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    final elbowAngle = angles['elbow'];
    if (elbowAngle == null) {
      return false;
    }
    
    // Should be 45-60° (not flared wide)
    return elbowAngle >= 35 && elbowAngle <= 70;
  }

  /// Check if hips are level (not sagging or piked)
  static bool hipAlignment(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    final leftHip = landmarks.leftHip.position;
    final rightHip = landmarks.rightHip.position;
    
    final diff = (leftHip.dy - rightHip.dy).abs();
    
    // Hips should be level
    return diff < 0.05;
  }

  /// Check shoulder position (retracted, not hunched)
  static bool shoulderPosition(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    final leftShoulder = landmarks.leftShoulder.position;
    final rightShoulder = landmarks.rightShoulder.position;
    
    final shoulderWidth = leftShoulder.dx - rightShoulder.dx;
    
    // Shoulders should be pulled back (not rounded forward)
    // This is a simplified check - could be enhanced
    return shoulderWidth > 0.15;
  }

  /// Check movement tempo (not too fast)
  static bool tempo(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    // This needs velocity data - would be passed in via angles map
    final velocity = angles['_velocity'];
    if (velocity == null) {
      return true;
    }
    
    // Max velocity threshold
    return velocity < 0.5;
  }

  /// Check balance (COM over feet)
  static bool balance(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    return BiomechanicsEngine.isBalanced(landmarks);
  }

  /// Check symmetry between left and right
  static bool symmetry(
    Map<String, double> angles,
    PoseLandmarks landmarks,
  ) {
    final leftElbow = angles['left_elbow'];
    final rightElbow = angles['right_elbow'];

    if (leftElbow == null || rightElbow == null) {
      return true;
    }
    
    final symmetryScore = BiomechanicsEngine.calculateSymmetry(
      leftElbow,
      rightElbow,
    );
    
    return symmetryScore > 0.8; // 80% symmetry
  }

  /// Check full range of motion
  static bool fullRangeOfMotion(
    Map<String, double> angles,
    PoseLandmarks landmarks, {
    required String angleKey,
    required double minAngle,
    required double maxAngle,
  }) {
    final angle = angles[angleKey];
    if (angle == null) {
      return false;
    }

    return angle >= minAngle && angle <= maxAngle;
  }
}
