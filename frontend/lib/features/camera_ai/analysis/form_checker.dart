import '../pose/pose_landmark_model.dart';
import 'angle_calculator.dart';

/// Elite Form feedback result
class FormFeedback {
  final bool isCorrect;
  final List<String> issues;
  final double accuracy; // 0-100%
  final Map<String, double> angles;
  final String? perfectionTip;

  FormFeedback({
    required this.isCorrect,
    required this.issues,
    required this.accuracy,
    required this.angles,
    this.perfectionTip,
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

/// Professional Form Checker with Degree-Specific Corrections
class FormChecker {
  static const double _perfectAccuracy = 100.0;

  /// Check push-up form with 3D joint analysis
  static FormFeedback checkPushupForm(PoseLandmarks pose) {
    final List<String> issues = [];
    final Map<String, double> angles = {};
    double totalDeduction = 0.0;

    // 1. Core / Hip Alignment (Perfect: 175-185°)
    final hipAngleL = AngleCalculator.getHipAngle(pose, leftSide: true);
    final hipAngleR = AngleCalculator.getHipAngle(pose, leftSide: false);
    final avgHipAngle = (hipAngleL + hipAngleR) / 2;
    angles['hip'] = avgHipAngle;

    if (avgHipAngle < 168) {
      final diff = (175 - avgHipAngle).round();
      issues.add('Hips are too low! Lift them $diff°');
      totalDeduction += 25.0;
    } else if (avgHipAngle > 192) {
      final diff = (avgHipAngle - 185).round();
      issues.add('Hips are too high! Lower them $diff°');
      totalDeduction += 20.0;
    }

    // 2. Arm Symmetry
    final leftElbow = AngleCalculator.getElbowAngle(pose, leftSide: true);
    final rightElbow = AngleCalculator.getElbowAngle(pose, leftSide: false);
    final elbowDiff = (leftElbow - rightElbow).abs();
    angles['elbowDiff'] = elbowDiff;

    if (elbowDiff > 12) {
      issues.add('Balance your arms! ${elbowDiff.round()}° difference.');
      totalDeduction += 15.0;
    }

    // 3. Head Neutrality
    final noseY = pose.nose.y;
    final shoulderY = (pose.leftShoulder.y + pose.rightShoulder.y) / 2;
    if (noseY > shoulderY + 0.08) {
      issues.add('Look down! Keep your neck aligned.');
      totalDeduction += 10.0;
    }

    final accuracy = (_perfectAccuracy - totalDeduction).clamp(0.0, 100.0);
    String? tip;
    if (accuracy >= 98) {
      tip = 'Elite form! Stay rock solid.';
    } else if (accuracy >= 90) {
      tip = 'Almost perfect. Focus on breathing.';
    }

    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
      perfectionTip: tip,
    );
  }

  /// Check squat form with depth precision
  static FormFeedback checkSquatForm(PoseLandmarks pose) {
    final List<String> issues = [];
    final Map<String, double> angles = {};
    double totalDeduction = 0.0;

    // 1. Knee Depth (Target: 85-95°)
    final kneeL = AngleCalculator.getKneeAngle(pose, leftSide: true);
    final kneeR = AngleCalculator.getKneeAngle(pose, leftSide: false);
    final avgKnee = (kneeL + kneeR) / 2;
    angles['knee'] = avgKnee;

    if (avgKnee > 102) {
      final diff = (avgKnee - 90).round();
      issues.add('Drop your hips $diff° deeper!');
      totalDeduction += 30.0;
    } else if (avgKnee < 75) {
      issues.add('Too deep! Stop at parallel.');
      totalDeduction += 15.0;
    }

    // 2. Torso Angle
    final hipAngle = AngleCalculator.getHipAngle(pose);
    angles['hip'] = hipAngle;
    if (hipAngle < 140) {
      issues.add('Chest up! Don\'t lean forward too much.');
      totalDeduction += 25.0;
    }

    final accuracy = (_perfectAccuracy - totalDeduction).clamp(0.0, 100.0);
    
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
      perfectionTip: accuracy > 95 ? 'Perfect depth! Drive through heels.' : null,
    );
  }

  /// Static analysis for Planks
  static FormFeedback checkPlankForm(PoseLandmarks pose) {
    final List<String> issues = [];
    final Map<String, double> angles = {};
    double totalDeduction = 0.0;

    final hipAngle = AngleCalculator.getHipAngle(pose);
    angles['hip'] = hipAngle;

    if (hipAngle < 172) {
      issues.add('Hips are sagging! Squeeze your core.');
      totalDeduction += 40.0;
    } else if (hipAngle > 188) {
      issues.add('Hips are too high! Flatten your back.');
      totalDeduction += 35.0;
    }

    final accuracy = (_perfectAccuracy - totalDeduction).clamp(0.0, 100.0);

    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
      perfectionTip: accuracy > 98 ? 'Absolute stability. Don\'t move.' : null,
    );
  }

  /// Entry point for all exercises
  static FormFeedback checkForm(String exerciseType, PoseLandmarks pose) {
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
      case 'push-up':
      case 'diamond_pushup':
        return checkPushupForm(pose);
      case 'squat':
      case 'sumo_squat':
        return checkSquatForm(pose);
      case 'plank':
        return checkPlankForm(pose);
      default:
        return FormFeedback.perfect();
    }
  }
}
