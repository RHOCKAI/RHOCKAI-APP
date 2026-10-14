import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/feature_flags.dart';
import 'voice_feedback_service.dart';

/// Performance input data from the just-completed set
class SetPerformanceData {
  final double averageAccuracy; // 0.0 - 100.0
  final double? previousSetAccuracy; // 0.0 - 100.0 (null if first set)
  final double? tempoScore; // 0.0 - 100.0 (or tempo quality)
  final bool tempoTooFast;

  const SetPerformanceData({
    required this.averageAccuracy,
    this.previousSetAccuracy,
    this.tempoScore,
    this.tempoTooFast = false,
  });
}

/// ⏱️ Smart Rest Timer + Adaptive Rest Service
///
/// Dynamically adjusts post-set rest durations based on biomechanical accuracy,
/// fatigue degradation, and tempo pacing. Provides voice cues at 30s, 10s, and 0s.
class AdaptiveRestService {
  final String exerciseType;
  final VoiceFeedbackService _voiceService = VoiceFeedbackService();

  Timer? _timer;
  int _totalRestSeconds = 60;
  int _remainingSeconds = 60;
  bool _isResting = false;

  void Function(int remaining, int total)? onTick;
  VoidCallback? onCompleted;

  bool get isResting => _isResting;
  int get remainingSeconds => _remainingSeconds;
  int get totalRestSeconds => _totalRestSeconds;
  double get progress => _totalRestSeconds > 0
      ? 1.0 - (_remainingSeconds / _totalRestSeconds).clamp(0.0, 1.0)
      : 1.0;

  AdaptiveRestService({
    required this.exerciseType,
    this.onTick,
    this.onCompleted,
  });

  /// Base rest duration mapped to movement biomechanical load (in seconds)
  static int getBaseRestForExercise(String exercise) {
    final key = exercise.toLowerCase();
    if (key.contains('squat') || key.contains('deadlift') || key.contains('lunge')) {
      return 90; // Heavy compound lower-body
    } else if (key.contains('plank') || key.contains('hold')) {
      return 45; // Isometric core hold
    } else if (key.contains('pushup') || key.contains('pullup') || key.contains('dip')) {
      return 60; // Upper body compound
    }
    return 60; // Default
  }

  /// Pure calculation function for rest duration (easily unit-tested)
  static int calculateAdaptiveRest({
    required String exerciseType,
    required SetPerformanceData performance,
    int? storedLastRest,
  }) {
    if (!FeatureFlags.isEnabled('adaptive_rest')) {
      return storedLastRest ?? getBaseRestForExercise(exerciseType);
    }

    int rest = getBaseRestForExercise(exerciseType);

    // Rule 1: Low accuracy (< 75%) indicates fatigue or form breakdown -> +25s
    if (performance.averageAccuracy < 75.0) {
      rest += 25;
    }

    // Rule 2: Form degradation > 15% compared to previous set -> +15s
    if (performance.previousSetAccuracy != null) {
      final drop = performance.previousSetAccuracy! - performance.averageAccuracy;
      if (drop > 15.0) {
        rest += 15;
      }
    }

    // Rule 3: Rep tempo too rushed (eccentric neglected or tempo < 60) -> +10s
    if (performance.tempoTooFast || (performance.tempoScore != null && performance.tempoScore! < 60.0)) {
      rest += 10;
    }

    // Hard biomechanical clamp: between 45s and 180s
    return rest.clamp(45, 180);
  }

  /// Calculates duration, persists setting, and launches countdown
  Future<int> startRest({
    required SetPerformanceData performance,
  }) async {
    cancel();

    int? savedRest;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedRest = prefs.getInt('rest_duration_${exerciseType.toLowerCase()}');
    } catch (e) {
      debugPrint('SharedPreferences read error: $e');
    }

    _totalRestSeconds = calculateAdaptiveRest(
      exerciseType: exerciseType,
      performance: performance,
      storedLastRest: savedRest,
    );
    _remainingSeconds = _totalRestSeconds;
    _isResting = true;

    // Persist adapted duration for this exercise
    unawaited(_saveRestPreference(_totalRestSeconds));

    // Announce rest start
    unawaited(_voiceService.announceRestStart(_totalRestSeconds));

    onTick?.call(_remainingSeconds, _totalRestSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        _remainingSeconds--;
        onTick?.call(_remainingSeconds, _totalRestSeconds);

        // Vocal cues at key intervals
        if (_remainingSeconds == 30) {
          unawaited(_voiceService.announceRestCountdown(30));
        } else if (_remainingSeconds == 10) {
          unawaited(_voiceService.announceRestCountdown(10));
        }
      } else {
        _remainingSeconds = 0;
        _isResting = false;
        timer.cancel();
        onTick?.call(0, _totalRestSeconds);
        unawaited(_voiceService.announceRestComplete());
        onCompleted?.call();
      }
    });

    return _totalRestSeconds;
  }

  /// Add extra seconds to rest (e.g. from voice command "add 30 seconds" or UI button)
  void addSeconds(int seconds) {
    if (!_isResting) {
      return;
    }
    _totalRestSeconds += seconds;
    _remainingSeconds += seconds;
    unawaited(_voiceService.announceRestExtended(seconds));
    onTick?.call(_remainingSeconds, _totalRestSeconds);
  }

  /// Skip rest immediately (e.g. "skip rest", "I'm ready", or UI button)
  void skipRest() {
    if (!_isResting) {
      return;
    }
    cancel();
    _remainingSeconds = 0;
    _isResting = false;
    onTick?.call(0, _totalRestSeconds);
    unawaited(_voiceService.announceRestComplete());
    onCompleted?.call();
  }

  /// Cancel countdown without triggering completion
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isResting = false;
  }

  Future<void> _saveRestPreference(int duration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('rest_duration_${exerciseType.toLowerCase()}', duration);
    } catch (e) {
      debugPrint('Failed to persist rest duration: $e');
    }
  }

  void dispose() {
    cancel();
  }
}
