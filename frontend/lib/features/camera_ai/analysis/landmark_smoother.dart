import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Implements Exponential Moving Average (EMA) to smooth landmark jitter.
class LandmarkSmoother {
  final double _alpha;
  Map<PoseLandmarkType, PoseLandmark> _previousLandmarks = {};

  /// [alpha] determines the smoothing factor. Lower is smoother.
  /// 0.4 for plank (slow), 0.6 for pushup/squat (fast).
  LandmarkSmoother({required double alpha}) : _alpha = alpha;

  /// Applies EMA smoothing to the incoming pose landmarks.
  Map<PoseLandmarkType, PoseLandmark> smooth(
      Map<PoseLandmarkType, PoseLandmark> currentLandmarks) {
    if (_previousLandmarks.isEmpty) {
      _previousLandmarks = Map.from(currentLandmarks);
      return currentLandmarks;
    }

    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};

    for (final entry in currentLandmarks.entries) {
      final type = entry.key;
      final current = entry.value;
      final previous = _previousLandmarks[type];

      if (previous == null) {
        smoothedLandmarks[type] = current;
        continue;
      }

      final smoothedX = previous.x + _alpha * (current.x - previous.x);
      final smoothedY = previous.y + _alpha * (current.y - previous.y);
      final smoothedZ = previous.z + _alpha * (current.z - previous.z);

      smoothedLandmarks[type] = PoseLandmark(
        type: type,
        x: smoothedX,
        y: smoothedY,
        z: smoothedZ,
        likelihood: current.likelihood,
      );
    }

    _previousLandmarks = smoothedLandmarks;
    return smoothedLandmarks;
  }

  /// Resets the smoother state (e.g., when a person leaves the frame).
  void reset() {
    _previousLandmarks.clear();
  }

  /// Cleans up resources.
  void dispose() {
    reset();
  }
}
