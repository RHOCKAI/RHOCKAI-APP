import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'one_euro_filter.dart';

/// Implements high-fidelity One Euro Filtering to smooth landmark jitter with adaptive low-pass filters.
class LandmarkSmoother {
  final Map<PoseLandmarkType, MultiDimensionOneEuroFilter> _filters = {};
  
  // Maintain backward compatibility parameter
  final double _alpha;

  /// [alpha] determines the smoothing factor threshold.
  /// Lower alpha (e.g. 0.4 for plank) uses heavier smoothing.
  LandmarkSmoother({required double alpha}) : _alpha = alpha;

  /// Applies One Euro Filter smoothing to the incoming pose landmarks.
  Map<PoseLandmarkType, PoseLandmark> smooth(
      Map<PoseLandmarkType, PoseLandmark> currentLandmarks) {
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};

    for (final entry in currentLandmarks.entries) {
      final type = entry.key;
      final current = entry.value;

      // Dynamically initialize 3D filters for each landmark type
      final filter = _filters.putIfAbsent(type, () {
        // Adjust cutoff based on alpha: lower alpha means slower/more stable exercise (like planks),
        // so we lower minCutoff for heavier smoothing.
        final minCutoff = _alpha < 0.5 ? 0.65 : 0.85;
        return MultiDimensionOneEuroFilter(
          minCutoff: minCutoff,
          beta: 0.015,
          dCutoff: 1.0,
        );
      });

      smoothedLandmarks[type] = filter.filter(current, timestamp);
    }

    return smoothedLandmarks;
  }

  /// Resets the smoother state (e.g., when a person leaves the frame).
  void reset() {
    for (final filter in _filters.values) {
      filter.reset();
    }
  }

  /// Cleans up resources.
  void dispose() {
    reset();
    _filters.clear();
  }
}

