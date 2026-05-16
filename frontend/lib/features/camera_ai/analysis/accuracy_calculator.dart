import 'dart:math';

/// Calculates accuracy for a rep and maintains session average.
class AccuracyCalculator {
  final List<double> _repAccuracies = [];
  double _lastAngle = -1;
  double _peakVelocity = 0;
  final List<double> _currentRepAngles = [];

  /// Calculate the accuracy of a single rep.
  ///
  /// Weighted Composite Formula:
  /// - 40% Depth Score: Did they hit the target angle?
  /// - 30% Symmetry Score: Left vs right side angle delta.
  /// - 20% Smoothness Score: Angle velocity (penalize jerky reps).
  /// - 10% Consistency Score: Variance across reps in session.
  double calculateRepAccuracy({
    required double targetDepth,
    required double achievedDepth,
    double symmetryDelta = 0.0,
  }) {
    double depthRatio = achievedDepth / max(targetDepth, 1.0);
    if (targetDepth < 100) {
      depthRatio = targetDepth / max(achievedDepth, 1.0);
    }
    double depthScore = (depthRatio.clamp(0.0, 1.0)) * 40.0;

    double symmetryScore = max(0.0, 30.0 - (symmetryDelta * 2.0));

    double smoothnessScore = max(0.0, 20.0 - (_peakVelocity / 10.0));

    double consistencyScore = 10.0;
    if (_repAccuracies.isNotEmpty) {
      double avgSoFar =
          _repAccuracies.reduce((a, b) => a + b) / _repAccuracies.length;
      double variance = (_repAccuracies.last - avgSoFar).abs();
      consistencyScore = max(0.0, 10.0 - (variance / 5.0));
    }

    double totalAccuracy =
        depthScore + symmetryScore + smoothnessScore + consistencyScore;
    totalAccuracy = totalAccuracy.clamp(0.0, 100.0);

    _repAccuracies.add(totalAccuracy);
    _currentRepAngles.clear();
    _peakVelocity = 0;

    return totalAccuracy;
  }

  /// Tracks angle velocity for smoothness calculations.
  void feedAngleForSmoothness(double angle) {
    if (_lastAngle != -1) {
      double velocity = (angle - _lastAngle).abs();
      if (velocity > _peakVelocity) {
        _peakVelocity = velocity;
      }
    }
    _lastAngle = angle;
    _currentRepAngles.add(angle);
  }

  /// Returns the average accuracy across all recorded reps.
  double calculateSessionAccuracy() {
    if (_repAccuracies.isEmpty) {
      return 0.0;
    }
    double total = _repAccuracies.reduce((a, b) => a + b);
    return (total / _repAccuracies.length).clamp(0.0, 100.0);
  }

  /// Resets calculator state.
  void reset() {
    _repAccuracies.clear();
    _currentRepAngles.clear();
    _lastAngle = -1;
    _peakVelocity = 0;
  }

  /// Cleans up resources.
  void dispose() {
    reset();
  }
}
