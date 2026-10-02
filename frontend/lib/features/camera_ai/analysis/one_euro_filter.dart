import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Single-dimension One Euro Filter.
/// Adaptive low-pass filter that adjusts cutoff frequency based on input velocity.
class OneEuroFilter {
  final double minCutoff;
  final double beta;
  final double dCutoff;

  double? _prevValue;
  double? _prevDeriv;
  int? _prevTimestamp;

  OneEuroFilter({
    required this.minCutoff,
    required this.beta,
    required this.dCutoff,
  });

  /// Filters a single signal value based on millisecond timestamp.
  double filter(double value, int timestamp) {
    if (_prevValue == null || _prevTimestamp == null) {
      _prevValue = value;
      _prevDeriv = 0.0;
      _prevTimestamp = timestamp;
      return value;
    }

    final dt = (timestamp - _prevTimestamp!) / 1000.0; // Convert to seconds
    if (dt <= 0.0) {
      return _prevValue!;
    }

    // 1. Calculate velocity (derivative)
    final deriv = (value - _prevValue!) / dt;

    // 2. Smooth velocity using simple low-pass filter
    final alphaD = _alpha(dt, dCutoff);
    final smoothedDeriv = _prevDeriv! + alphaD * (deriv - _prevDeriv!);

    // 3. Compute adaptive cutoff frequency based on velocity magnitude
    final cutoff = minCutoff + beta * smoothedDeriv.abs();

    // 4. Smooth signal value using adaptive cutoff frequency
    final alpha = _alpha(dt, cutoff);
    final smoothedValue = _prevValue! + alpha * (value - _prevValue!);

    // 5. Update filter states
    _prevValue = smoothedValue;
    _prevDeriv = smoothedDeriv;
    _prevTimestamp = timestamp;

    return smoothedValue;
  }

  double _alpha(double dt, double cutoff) {
    final tau = 1.0 / (2.0 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / dt);
  }

  /// Reset the filter memory
  void reset() {
    _prevValue = null;
    _prevDeriv = null;
    _prevTimestamp = null;
  }
}

/// 3D One Euro Filter designed specifically for smoothing ML Kit PoseLandmarks.
class MultiDimensionOneEuroFilter {
  late final OneEuroFilter _filterX;
  late final OneEuroFilter _filterY;
  late final OneEuroFilter _filterZ;

  MultiDimensionOneEuroFilter({
    double minCutoff = 0.85,
    double beta = 0.015,
    double dCutoff = 1.0,
  }) {
    _filterX = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff);
    _filterY = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff);
    _filterZ = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff);
  }

  /// Filters X, Y, and Z coordinates of a PoseLandmark
  PoseLandmark filter(PoseLandmark landmark, int timestamp) {
    final x = _filterX.filter(landmark.x, timestamp);
    final y = _filterY.filter(landmark.y, timestamp);
    final z = _filterZ.filter(landmark.z, timestamp);

    return PoseLandmark(
      type: landmark.type,
      x: x,
      y: y,
      z: z,
      likelihood: landmark.likelihood,
    );
  }

  /// Reset all dimensions of the filter
  void reset() {
    _filterX.reset();
    _filterY.reset();
    _filterZ.reset();
  }
}
