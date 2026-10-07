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

  /// Check push-up form with joint analysis
  static FormFeedback checkPushupForm(PoseLandmarks pose) {
    final List<String> issues = [];
    final Map<String, double> angles = {};
    double totalDeduction = 0.0;

    // 1. Core / Hip Alignment (Normal range: 155-195°)
    final hipAngle = AngleCalculator.getHipAngle(pose);
    angles['hip'] = hipAngle;

    if (hipAngle < 155) {
      final diff = (170 - hipAngle).round();
      issues.add('Hips are sagging! Lift them $diff°');
      totalDeduction += 20.0;
    } else if (hipAngle > 200) {
      final diff = (hipAngle - 180).round();
      issues.add('Hips are too high! Lower them $diff°');
      totalDeduction += 15.0;
    }

    // 2. Arm Symmetry (only evaluate if both arms are clearly visible from front)
    final bothArmsClear = pose.leftElbow.likelihood > 0.45 &&
        pose.rightElbow.likelihood > 0.45 &&
        pose.leftWrist.likelihood > 0.45 &&
        pose.rightWrist.likelihood > 0.45;

    if (bothArmsClear) {
      final leftElbow = AngleCalculator.getElbowAngle(pose, leftSide: true);
      final rightElbow = AngleCalculator.getElbowAngle(pose, leftSide: false);
      final elbowDiff = (leftElbow - rightElbow).abs();
      angles['elbowDiff'] = elbowDiff;

      if (elbowDiff > 25) {
        issues.add('Balance your arms evenly.');
        totalDeduction += 10.0;
      }
    }

    final accuracy = (_perfectAccuracy - totalDeduction).clamp(0.0, 100.0);
    String? tip;
    if (accuracy >= 95) {
      tip = 'Great form! Keep your core tight.';
    } else if (accuracy >= 85) {
      tip = 'Solid rep! Maintain control.';
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

    // 1. Knee Depth
    final kneeAngle = AngleCalculator.getAverageKneeAngle(pose);
    angles['knee'] = kneeAngle;

    if (kneeAngle > 115) {
      issues.add('Drop your hips a bit deeper!');
      totalDeduction += 20.0;
    } else if (kneeAngle < 70) {
      issues.add('Too deep! Stop at parallel.');
      totalDeduction += 10.0;
    }

    // 2. Torso Angle
    final hipAngle = AngleCalculator.getHipAngle(pose);
    angles['hip'] = hipAngle;
    if (hipAngle < 120) {
      issues.add('Chest up! Don\'t lean forward too much.');
      totalDeduction += 15.0;
    }

    final accuracy = (_perfectAccuracy - totalDeduction).clamp(0.0, 100.0);

    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
      perfectionTip:
          accuracy > 90 ? 'Great depth! Drive through your heels.' : null,
    );
  }

  /// Static analysis for Planks
  static FormFeedback checkPlankForm(PoseLandmarks pose) {
    final List<String> issues = [];
    final Map<String, double> angles = {};
    double totalDeduction = 0.0;

    final hipAngle = AngleCalculator.getHipAngle(pose);
    angles['hip'] = hipAngle;

    if (hipAngle < 160) {
      issues.add('Hips are sagging! Squeeze your core.');
      totalDeduction += 25.0;
    } else if (hipAngle > 200) {
      issues.add('Hips are too high! Flatten your back.');
      totalDeduction += 20.0;
    }

    final accuracy = (_perfectAccuracy - totalDeduction).clamp(0.0, 100.0);

    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: accuracy,
      angles: angles,
      perfectionTip: accuracy > 90 ? 'Steady hold. Keep breathing.' : null,
    );
  }

  /// Entry point for all exercises
  static FormFeedback checkForm(String exerciseType, PoseLandmarks pose) {
    final lower = exerciseType.toLowerCase();
    if (lower.contains('pushup') || lower.contains('push-up') || lower.contains('dip')) {
      return checkPushupForm(pose);
    } else if (lower.contains('squat') || lower.contains('lunge')) {
      return checkSquatForm(pose);
    } else if (lower.contains('plank')) {
      return checkPlankForm(pose);
    } else {
      // Default / generic check
      return FormFeedback.perfect();
    }
  }
}
