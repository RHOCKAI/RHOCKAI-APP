import '../pose/pose_landmark_model.dart';
import 'angle_calculator.dart';
import '../../../core/constants/exercises.dart';

/// Form feedback result
class FormFeedback {
  final bool isCorrect;
  final List<String> issues;
  final double accuracy; // 0-100%
  final Map<String, double> angles;
  
  FormFeedback({
    required this.isCorrect,
    required this.issues,
    required this.accuracy,
    required this.angles,
  });
  
  factory FormFeedback.perfect() {
    return FormFeedback(
      isCorrect: true,
      issues: [],
      accuracy: 100.0,
      angles: {},
    );
  }
}

/// Check exercise form and provide feedback
class FormChecker {
  /// Check push-up form
  static FormFeedback checkPushupForm(PoseLandmarks pose) {
    final List<String> issues = [];
    int correctPoints = 0;
    const int totalPoints = 4;
    final Map<String, double> angles = {};
    
    // 1. Back alignment (hip angle should be ~180°)
    final hipAngleLeft = AngleCalculator.getHipAngle(pose, leftSide: true);
    final hipAngleRight = AngleCalculator.getHipAngle(pose, leftSide: false);
    final avgHipAngle = (hipAngleLeft + hipAngleRight) / 2;
    angles['hip'] = avgHipAngle;
    
    if (avgHipAngle < 160 || avgHipAngle > 200) {
      issues.add('Keep your back straight!');
    } else {
      correctPoints++;
    }
    
    // 2. Elbow angle symmetry (both arms should work equally)
    final leftElbowAngle = AngleCalculator.getElbowAngle(pose, leftSide: true);
    final rightElbowAngle = AngleCalculator.getElbowAngle(pose, leftSide: false);
    angles['leftElbow'] = leftElbowAngle;
    angles['rightElbow'] = rightElbowAngle;
    
    if ((leftElbowAngle - rightElbowAngle).abs() > 
        ExerciseThresholds.armSymmetryTolerance) {
      issues.add('Balance both arms equally!');
    } else {
      correctPoints++;
    }
    
    // 3. Head alignment (neutral position)
    final noseY = pose.nose.y;
    final shoulderY = (pose.leftShoulder.y + pose.rightShoulder.y) / 2;
    
    if ((noseY - shoulderY).abs() > 0.2) {
      issues.add('Keep your head neutral!');
    } else {
      correctPoints++;
    }
    
    // 4. Core engagement (check if hips are not sagging or piking)
    if (avgHipAngle < 150) {
      issues.add("Don't let your hips sag!");
    } else if (avgHipAngle > 210) {
      issues.add("Don't pike your hips up!");
    } else {
      correctPoints++;
    }
    
    final accuracy = (correctPoints / totalPoints) * 100;
    
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
    );
  }
  
  /// Check squat form
  static FormFeedback checkSquatForm(PoseLandmarks pose) {
    final List<String> issues = [];
    int correctPoints = 0;
    const int totalPoints = 4;
    final Map<String, double> angles = {};
    
    // 1. Knee angle (should reach ~90° at bottom)
    final leftKneeAngle = AngleCalculator.getKneeAngle(pose, leftSide: true);
    final rightKneeAngle = AngleCalculator.getKneeAngle(pose, leftSide: false);
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
    angles['knee'] = avgKneeAngle;
    
    if (avgKneeAngle < 80 || avgKneeAngle > 100) {
      if (avgKneeAngle > 100) {
        issues.add('Go deeper!');
      } else {
        issues.add("Don't go below 90°!");
      }
    } else {
      correctPoints++;
    }
    
    // 2. Back angle (keep chest up)
    final hipAngle = AngleCalculator.getHipAngle(pose);
    angles['hip'] = hipAngle;
    
    if (hipAngle < 140) {
      issues.add('Keep your chest up!');
    } else {
      correctPoints++;
    }
    
    // 3. Knees tracking over toes (shouldn't collapse inward)
    final leftKneeX = pose.leftKnee.x;
    final rightKneeX = pose.rightKnee.x;
    final shoulderWidth = (pose.leftShoulder.x - pose.rightShoulder.x).abs();
    final kneeWidth = (leftKneeX - rightKneeX).abs();
    
    if (kneeWidth < shoulderWidth * 0.7) {
      issues.add("Don't let knees cave inward!");
    } else {
      correctPoints++;
    }
    
    // 4. Weight distribution (knees shouldn't pass toes too much)
    final leftKneeToAnkle = (pose.leftKnee.x - pose.leftAnkle.x).abs();
    final rightKneeToAnkle = (pose.rightKnee.x - pose.rightAnkle.x).abs();
    
    if (leftKneeToAnkle > 0.15 || rightKneeToAnkle > 0.15) {
      issues.add("Don't let knees pass your toes!");
    } else {
      correctPoints++;
    }
    
    final accuracy = (correctPoints / totalPoints) * 100;
    
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
    );
  }
  
  /// Check plank form
  static FormFeedback checkPlankForm(PoseLandmarks pose) {
    final List<String> issues = [];
    int correctPoints = 0;
    const int totalPoints = 3;
    final Map<String, double> angles = {};
    
    // 1. Body alignment (straight line from shoulders to ankles)
    final hipAngle = AngleCalculator.getHipAngle(pose);
    angles['hip'] = hipAngle;
    
    final isBodyStraight = (hipAngle - 180).abs() <= ExerciseThresholds.plankTolerance;
    
    if (!isBodyStraight) {
      if (hipAngle < 165) {
        issues.add("Don't let your hips sag!");
      } else {
        issues.add("Don't pike your hips up!");
      }
    } else {
      correctPoints++;
    }
    
    // 2. Shoulder alignment (elbows should be below shoulders)
    final leftShoulderToElbow = (pose.leftShoulder.x - pose.leftElbow.x).abs();
    final rightShoulderToElbow = (pose.rightShoulder.x - pose.rightElbow.x).abs();
    
    if (leftShoulderToElbow > 0.1 || rightShoulderToElbow > 0.1) {
      issues.add('Keep elbows under shoulders!');
    } else {
      correctPoints++;
    }
    
    // 3. Head position (neutral, looking down)
    final noseY = pose.nose.y;
    final shoulderY = (pose.leftShoulder.y + pose.rightShoulder.y) / 2;
    
    if (noseY < shoulderY - 0.3) {
      issues.add('Keep head neutral - look down!');
    } else {
      correctPoints++;
    }
    
    final accuracy = (correctPoints / totalPoints) * 100;
    
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
    );
  }

  /// Check Pike Push-up form (V-shape)
  static FormFeedback checkPikePushupForm(PoseLandmarks pose) {
    final List<String> issues = [];
    int correctPoints = 0;
    const int totalPoints = 3;
    final Map<String, double> angles = {};

    // 1. Hip angle (should be around 90-110° for a V-shape)
    final hipAngle = AngleCalculator.getHipAngle(pose);
    angles['hip'] = hipAngle;
    if (hipAngle < 80 || hipAngle > 120) {
      issues.add('Maintain a V-shape with your hips!');
    } else {
      correctPoints++;
    }

    // 2. Elbow tracking
    final elbowAngle = AngleCalculator.getAverageElbowAngle(pose);
    angles['elbow'] = elbowAngle;
    correctPoints++; // Just tracking for now

    // 3. Depth (head towards floor)
    final noseY = pose.nose.y;
    final wristY = (pose.leftWrist.y + pose.rightWrist.y) / 2;
    if (noseY > wristY - 0.1) {
      issues.add('Go lower!');
    } else {
      correctPoints++;
    }

    final accuracy = (correctPoints / totalPoints) * 100;
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
    );
  }

  /// Check Diamond Push-up form (Hands close)
  static FormFeedback checkDiamondPushupForm(PoseLandmarks pose) {
    final feedback = checkPushupForm(pose);
    final List<String> issues = List.from(feedback.issues);
    
    // Additional Diamond check: Hand proximity
    final handDist = AngleCalculator.calculateDistance(pose.leftWrist, pose.rightWrist);
    if (handDist > 0.2) {
      issues.add('Keep your hands close together!');
    }
    
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: feedback.accuracy,
      angles: feedback.angles,
    );
  }

  /// Check Archer Push-up form (One arm straight)
  static FormFeedback checkArcherPushupForm(PoseLandmarks pose) {
    final List<String> issues = [];
    final leftElbow = AngleCalculator.getElbowAngle(pose, leftSide: true);
    final rightElbow = AngleCalculator.getElbowAngle(pose, leftSide: false);
    
    // In Archer, one should be bent, one should be relatively straight (> 150°)
    if (leftElbow < 140 && rightElbow < 140) {
      issues.add('Keep one arm straight!');
    }
    
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: 85.0, // Base accuracy for detection
      angles: {'leftElbow': leftElbow, 'rightElbow': rightElbow},
    );
  }

  /// Check Pistol Squat form (Single leg)
  static FormFeedback checkPistolSquatForm(PoseLandmarks pose) {
    final List<String> issues = [];
    final leftKnee = AngleCalculator.getKneeAngle(pose, leftSide: true);
    final rightKnee = AngleCalculator.getKneeAngle(pose, leftSide: false);
    
    // One leg should be very bent, other should be extended
    if (leftKnee > 120 && rightKnee > 120) {
      issues.add('Sit deeper on one leg!');
    }
    
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: 80.0,
      angles: {'leftKnee': leftKnee, 'rightKnee': rightKnee},
    );
  }

  /// Check Lunge form
  static FormFeedback checkLungeForm(PoseLandmarks pose) {
    final List<String> issues = [];
    final frontKnee = AngleCalculator.getKneeAngle(pose, leftSide: true); // Simplified
    
    if (frontKnee > 110) {
      issues.add('Step further and drop your back knee!');
    }
    
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: 90.0,
      angles: {'knee': frontKnee},
    );
  }

  /// Get form checker based on exercise type
  static FormFeedback checkForm(String exerciseType, PoseLandmarks pose) {
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
      case 'push-up':
        return checkPushupForm(pose);
      case 'diamond_pushup':
      case 'diamond push-up':
        return checkDiamondPushupForm(pose);
      case 'pike_pushup':
      case 'pike push-up':
        return checkPikePushupForm(pose);
      case 'archer_pushup':
      case 'archer push-up':
        return checkArcherPushupForm(pose);
      case 'squat':
        return checkSquatForm(pose);
      case 'pistol_squat':
      case 'pistol squat':
        return checkPistolSquatForm(pose);
      case 'lunge':
      case 'reverse_lunge':
        return checkLungeForm(pose);
      case 'plank':
        return checkPlankForm(pose);
      default:
        return FormFeedback.perfect();
    }
      default:
        return FormFeedback.perfect();
    }
  }
}
