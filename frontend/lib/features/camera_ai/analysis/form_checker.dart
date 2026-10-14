import '../pose/pose_landmark_model.dart';
import 'angle_calculator.dart';

/// Rule-based posture feedback. The score is a heuristic, not a measured
/// probability or a clinically validated accuracy percentage.
class FormFeedback {
  final bool isCorrect;
  final bool isAnalyzable;
  final List<String> issues;
  final double accuracy;
  final Map<String, double> angles;
  final String? perfectionTip;

  FormFeedback({
    required this.isCorrect,
    required this.issues,
    required this.accuracy,
    required this.angles,
    this.perfectionTip,
    this.isAnalyzable = true,
  });

  factory FormFeedback.unavailable(String message) => FormFeedback(
    isCorrect: false,
    isAnalyzable: false,
    issues: [message],
    accuracy: 0,
    angles: const {},
  );
}

class FormChecker {
  static const double _perfectAccuracy = 100.0;
  static const double _minimumConfidence = 0.3;

  static FormFeedback checkPushupForm(PoseLandmarks pose) {
    if (!pose.hasExerciseConfidence('pushup', _minimumConfidence)) {
      return _unavailable();
    }

    final issues = <String>[];
    final angles = <String, double>{};
    var deduction = 0.0;

    final hipAngle = AngleCalculator.getHipAngle(pose);
    if (!hipAngle.isFinite) return _unavailable();
    angles['hip'] = hipAngle;

    if (hipAngle < 155) {
      issues.add('Hips are sagging. Keep your body in a straighter line.');
      deduction += 20;
    } else if (hipAngle > 200) {
      issues.add(
        'Hips are too high. Lower them into line with your shoulders.',
      );
      deduction += 15;
    }

    final leftElbow = AngleCalculator.getElbowAngle(pose, leftSide: true);
    final rightElbow = AngleCalculator.getElbowAngle(pose, leftSide: false);
    if (leftElbow.isFinite && rightElbow.isFinite) {
      final elbowDiff = (leftElbow - rightElbow).abs();
      angles['elbowDiff'] = elbowDiff;
      if (elbowDiff > 25) {
        issues.add('Keep both arms working evenly.');
        deduction += 10;
      }
    }

    final score = (_perfectAccuracy - deduction).clamp(0.0, 100.0).toDouble();
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: score,
      angles: angles,
      perfectionTip: score >= 95
          ? 'Good alignment. Keep your core engaged.'
          : null,
    );
  }

  static FormFeedback checkSquatForm(PoseLandmarks pose) {
    if (!pose.hasExerciseConfidence('squat', _minimumConfidence)) {
      return _unavailable();
    }

    final issues = <String>[];
    final angles = <String, double>{};
    var deduction = 0.0;

    final kneeAngle = AngleCalculator.getAverageKneeAngle(pose);
    final hipAngle = AngleCalculator.getHipAngle(pose);
    if (!kneeAngle.isFinite || !hipAngle.isFinite) return _unavailable();
    angles['knee'] = kneeAngle;
    angles['hip'] = hipAngle;

    if (kneeAngle > 115) {
      issues.add('Move a little deeper while keeping control.');
      deduction += 20;
    } else if (kneeAngle < 70) {
      issues.add('Reduce depth to a range you can control comfortably.');
      deduction += 10;
    }

    if (hipAngle < 120) {
      issues.add('Raise your chest and keep your torso controlled.');
      deduction += 15;
    }

    final score = (_perfectAccuracy - deduction).clamp(0.0, 100.0).toDouble();
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: score,
      angles: angles,
      perfectionTip: score > 90
          ? 'Good depth. Keep pressure through your feet.'
          : null,
    );
  }

  static FormFeedback checkPlankForm(PoseLandmarks pose) {
    if (!pose.hasExerciseConfidence('plank', _minimumConfidence)) {
      return _unavailable();
    }

    final hipAngle = AngleCalculator.getHipAngle(pose);
    if (!hipAngle.isFinite) return _unavailable();

    final issues = <String>[];
    var deduction = 0.0;
    if (hipAngle < 160) {
      issues.add('Your hips are sagging. Brace your core.');
      deduction += 25;
    } else if (hipAngle > 200) {
      issues.add('Lower your hips into line with your shoulders.');
      deduction += 20;
    }

    final score = (_perfectAccuracy - deduction).clamp(0.0, 100.0).toDouble();
    return FormFeedback(
      isCorrect: issues.isEmpty,
      issues: issues,
      accuracy: score,
      angles: {'hip': hipAngle},
      perfectionTip: score > 90 ? 'Hold steady and keep breathing.' : null,
    );
  }

  static bool supportsExercise(String exerciseType) {
    final lower = exerciseType
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    return lower.contains('pushup') ||
        lower.contains('dip') ||
        lower.contains('squat') ||
        lower.contains('lunge') ||
        lower.contains('plank');
  }

  static FormFeedback checkForm(String exerciseType, PoseLandmarks pose) {
    final lower = exerciseType
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    if (lower.contains('pushup') || lower.contains('dip')) {
      return checkPushupForm(pose);
    }
    if (lower.contains('squat') || lower.contains('lunge')) {
      return checkSquatForm(pose);
    }
    if (lower.contains('plank')) {
      return checkPlankForm(pose);
    }
    return FormFeedback.unavailable(
      'Form analysis is not available for this exercise yet.',
    );
  }

  static FormFeedback _unavailable() => FormFeedback.unavailable(
    'Move fully into frame so the required joints are visible.',
  );
}
