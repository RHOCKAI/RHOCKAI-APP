import '../pose/pose_landmark_model.dart';
import 'exercise_model.dart';

/// Generic rep detector that works for all exercise types
/// 
/// Supports:
/// - Flexion-extension (push-ups, squats)
/// - Hold-time (planks, wall sits)
/// - Multi-phase (burpees)
/// - Alternating (mountain climbers)
class RepDetector {
  final ExerciseDefinition exercise;
  
  RepState _currentState = RepState.waiting;
  int _repCount = 0;
  double? _minAngleAchieved;
  double? _maxAngleAchieved;
  DateTime? _holdStartTime;
  int _currentPhase = 0;
  
  // For alternating exercises
  bool _leftSideActive = true;
  
  // History tracking
  final List<DateTime> _repTimestamps = [];
  final List<double> _repDurations = [];

  RepDetector(this.exercise) {
    reset();
  }

  /// Process new pose data and detect reps
  RepDetectionResult process(
    PoseLandmarks landmarks,
    Map<String, double> angles,
  ) {
    bool repJustCompleted = false;
    
    switch (exercise.repDetection.type) {
      case RepType.flexionExtension:
        repJustCompleted = _detectFlexionExtension(angles);
        break;
        
      case RepType.holdTime:
        _detectHoldTime();
        break;
        
      case RepType.multiPhase:
        repJustCompleted = _detectMultiPhase(angles, landmarks);
        break;
        
      case RepType.alternating:
        repJustCompleted = _detectAlternating(angles, landmarks);
        break;
        
      case RepType.count:
        // Simple count increment (for jumping jacks, etc.)
        break;
    }
    
    final currentAngle = angles[exercise.repDetection.primaryAngle];
    
    return RepDetectionResult(
      repCount: _repCount,
      currentState: _currentState,
      currentAngle: currentAngle,
      minAngleAchieved: _minAngleAchieved,
      maxAngleAchieved: _maxAngleAchieved,
      holdDuration: _holdStartTime != null 
          ? DateTime.now().difference(_holdStartTime!) 
          : null,
      repJustCompleted: repJustCompleted,
    );
  }

  /// Detect flexion-extension reps (push-ups, squats, etc.)
  bool _detectFlexionExtension(Map<String, double> angles) {
    final config = exercise.repDetection;
    final angle = angles[config.primaryAngle];
    
    if (angle == null) {
      return false;
    }
    
    final downThreshold = config.downThreshold!;
    final upThreshold = config.upThreshold!;
    
    bool repCompleted = false;
    
    switch (_currentState) {
      case RepState.waiting:
        // Starting position (straight/up)
        if (angle > upThreshold) {
          _currentState = RepState.goingDown;
          _maxAngleAchieved = angle;
        }
        break;
        
      case RepState.goingDown:
        // Track minimum angle
        if (_minAngleAchieved == null || angle < _minAngleAchieved!) {
          _minAngleAchieved = angle;
        }
        
        // Reached bottom position
        if (angle < downThreshold) {
          _currentState = RepState.goingUp;
        }
        break;
        
      case RepState.goingUp:
        // Track maximum angle
        if (_maxAngleAchieved == null || angle > _maxAngleAchieved!) {
          _maxAngleAchieved = angle;
        }
        
        // Completed rep (back to top)
        if (angle > upThreshold && _minAngleAchieved != null && _minAngleAchieved! < downThreshold) {
          _repCount++;
          _repTimestamps.add(DateTime.now());
          repCompleted = true;
          
          // Calculate rep duration
          if (_repTimestamps.length > 1) {
            final duration = _repTimestamps.last.difference(
              _repTimestamps[_repTimestamps.length - 2]
            ).inMilliseconds / 1000.0;
            _repDurations.add(duration);
          }
          
          // Reset for next rep
          _currentState = RepState.waiting;
          _minAngleAchieved = null;
          _maxAngleAchieved = null;
        }
        break;
        
      default:
        break;
    }
    
    return repCompleted;
  }

  /// Detect hold-time exercises (planks, wall sits)
  void _detectHoldTime() {
    if (_holdStartTime == null) {
      _holdStartTime = DateTime.now();
      _currentState = RepState.holding;
    }
    
    // Count is based on hold duration
    final holdDuration = DateTime.now().difference(_holdStartTime!);
    _repCount = holdDuration.inSeconds;
  }

  /// Detect multi-phase exercises (burpees)
  bool _detectMultiPhase(Map<String, double> angles, PoseLandmarks landmarks) {
    final phases = exercise.repDetection.phases!;
    
    if (_currentPhase >= phases.length) {
      // Completed all phases = 1 rep
      _repCount++;
      _repTimestamps.add(DateTime.now());
      _currentPhase = 0;
      return true;
    }
    
    final currentPhaseConfig = phases[_currentPhase];
    bool phaseCompleted = true;
    
    // Check if all angle thresholds for this phase are met
    for (final entry in currentPhaseConfig.angleThresholds.entries) {
      final angle = angles[entry.key];
      if (angle == null || angle > entry.value) {
        phaseCompleted = false;
        break;
      }
    }
    
    if (phaseCompleted) {
      _currentPhase++;
    }
    
    return false;
  }

  /// Detect alternating exercises (mountain climbers)
  bool _detectAlternating(Map<String, double> angles, PoseLandmarks landmarks) {
    // Track knee height alternation
    final leftKneeHeight = landmarks.leftKnee.position.dy;
    final rightKneeHeight = landmarks.rightKnee.position.dy;
    
    // Left knee forward (higher in frame)
    if (_leftSideActive && rightKneeHeight < leftKneeHeight) {
      _leftSideActive = false;
      _repCount++;
      _repTimestamps.add(DateTime.now());
      return true;
    }
    
    // Right knee forward (higher in frame)
    if (!_leftSideActive && leftKneeHeight < rightKneeHeight) {
      _leftSideActive = true;
      // Don't count both sides
    }
    
    return false;
  }

  /// Manually increment counter (for exercises like jumping jacks)
  void incrementCount() {
    _repCount++;
    _repTimestamps.add(DateTime.now());
  }

  /// Get average rep duration
  double getAverageRepDuration() {
    if (_repDurations.isEmpty) {
      return 0.0;
    }
    return _repDurations.reduce((a, b) => a + b) / _repDurations.length;
  }

  /// Get current reps per minute
  double getCurrentRPM() {
    if (_repTimestamps.length < 2) {
      return 0.0;
    }
    
    final recentReps = _repTimestamps.length >= 5 
        ? _repTimestamps.sublist(_repTimestamps.length - 5)
        : _repTimestamps;
    
    if (recentReps.length < 2) {
      return 0.0;
    }
    
    final duration = recentReps.last.difference(recentReps.first);
    final minutes = duration.inSeconds / 60.0;
    
    if (minutes == 0) {
      return 0.0;
    }
    
    return recentReps.length / minutes;
  }

  /// Detect fatigue based on rep speed degradation
  bool detectFatigue({double threshold = 20.0}) {
    if (_repDurations.length < 10) {
      return false;
    }
    
    final firstFive = _repDurations.take(5).toList();
    final lastFive = _repDurations.skip(_repDurations.length - 5).toList();
    
    final firstAvg = firstFive.reduce((a, b) => a + b) / 5;
    final lastAvg = lastFive.reduce((a, b) => a + b) / 5;
    
    final slowdownPercent = ((lastAvg - firstAvg) / firstAvg) * 100;
    
    return slowdownPercent > threshold;
  }

  /// Reset detector state
  void reset() {
    _currentState = RepState.waiting;
    _repCount = 0;
    _minAngleAchieved = null;
    _maxAngleAchieved = null;
    _holdStartTime = null;
    _currentPhase = 0;
    _leftSideActive = true;
    _repTimestamps.clear();
    _repDurations.clear();
  }

  /// Get rep count
  int get repCount => _repCount;
  
  /// Get current state
  RepState get currentState => _currentState;
  
  /// Get rep timestamps
  List<DateTime> get repTimestamps => List.unmodifiable(_repTimestamps);
}
