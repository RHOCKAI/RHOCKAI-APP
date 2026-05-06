import '../pose/pose_landmark_model.dart';
import 'angle_calculator.dart';
import 'tempo_analyzer.dart';
import '../../../core/constants/exercises.dart';


/// Rep detection phases
enum RepPhase {
  up, // Starting position
  down, // Bottom position
  transition, // Moving
}

/// High-Precision Rep Counting State Machine
class RepStateMachine {
  final ExerciseType exerciseType;

  RepPhase currentPhase = RepPhase.up;
  int repCount = 0;
  bool isFormCorrect = true;
  double lastTempoScore = 0.0;
  double smoothnessScore = 100.0;
  String tempoFeedback = '';

  late double downAngleThreshold;
  late double upAngleThreshold;

  late TempoAnalyzer _tempoAnalyzer;

  DateTime? lastRepTime;
  
  // High-precision tracking
  final List<double> _angleHistory = [];
  static const int _historyCapacity = 15;
  double _lastVelocity = 0.0;

  RepStateMachine(this.exerciseType) {
    _initializeThresholds();
    _initializeTempoAnalyzer();
  }

  void _initializeTempoAnalyzer() {
    final data = Exercises.getById(exerciseType.name);
    _tempoAnalyzer = TempoAnalyzer(data?.idealTempo ?? const ExerciseTempo());
  }

  void _initializeThresholds() {
    switch (exerciseType) {
      case ExerciseType.pushup:
      case ExerciseType.diamondPushup:
      case ExerciseType.archerPushup:
      case ExerciseType.spidermanPushup:
        downAngleThreshold = 95.0; 
        upAngleThreshold = 160.0;
        break;
      case ExerciseType.squat:
      case ExerciseType.sumoSquat:
        downAngleThreshold = 100.0;
        upAngleThreshold = 165.0;
        break;
      case ExerciseType.plank:
      case ExerciseType.sidePlank:
        downAngleThreshold = 0;
        upAngleThreshold = 0;
        break;
      default:
        downAngleThreshold = 90.0;
        upAngleThreshold = 160.0;
    }
  }

  /// Process pose and update rep state with jitter detection
  bool processPose(PoseLandmarks pose) {
    final angle = _getRelevantAngle(pose);
    _updateTracking(angle);

    // State machine logic
    switch (currentPhase) {
      case RepPhase.up:
        if (angle < downAngleThreshold) {
          currentPhase = RepPhase.down;
          _tempoAnalyzer.recordPhaseStart(); 
          smoothnessScore = 100.0; // Reset for new rep
        }
        break;

      case RepPhase.down:
        if (angle > upAngleThreshold) {
          if (_isValidRep()) {
            repCount++;
            final concentricDuration = _tempoAnalyzer.completePhase();
            _tempoAnalyzer.updateRepDurations(1.5, 0.2, concentricDuration);

            lastTempoScore = _tempoAnalyzer.calculateScore();
            tempoFeedback = _tempoAnalyzer.getTempoFeedback();
            lastRepTime = DateTime.now();
            currentPhase = RepPhase.up;
            return true;
          }
        }
        break;

      case RepPhase.transition:
        break;
    }

    isFormCorrect = _checkBasicForm(pose);
    return false;
  }

  void _updateTracking(double currentAngle) {
    if (_angleHistory.isNotEmpty) {
      final velocity = (currentAngle - _angleHistory.last).abs();
      // If velocity changes direction rapidly (acceleration jitter), reduce smoothness
      if ((velocity - _lastVelocity).abs() > 15.0) {
        smoothnessScore = (smoothnessScore - 5.0).clamp(0.0, 100.0);
      }
      _lastVelocity = velocity;
    }
    
    _angleHistory.add(currentAngle);
    if (_angleHistory.length > _historyCapacity) {
      _angleHistory.removeAt(0);
    }
  }

  double _getRelevantAngle(PoseLandmarks pose) {
    switch (exerciseType) {
      case ExerciseType.pushup:
      case ExerciseType.diamondPushup:
      case ExerciseType.archerPushup:
      case ExerciseType.spidermanPushup:
      case ExerciseType.tricepDip:
      case ExerciseType.pikePushup:
        return AngleCalculator.getAverageElbowAngle(pose);
      case ExerciseType.squat:
      case ExerciseType.sumoSquat:
      case ExerciseType.lunge:
      case ExerciseType.reverseLunge:
      case ExerciseType.pistolSquat:
        return AngleCalculator.getAverageKneeAngle(pose);
      default:
        return AngleCalculator.getHipAngle(pose);
    }
  }

  bool _isValidRep() {
    if (lastRepTime == null) {
      return true;
    }
    final timeSinceLastRep = DateTime.now().difference(lastRepTime!);
    return timeSinceLastRep.inMilliseconds >= ExerciseThresholds.minRepDurationMs &&
           timeSinceLastRep.inMilliseconds <= ExerciseThresholds.maxRepDurationMs;
  }

  bool _checkBasicForm(PoseLandmarks pose) {
    final hipAngle = AngleCalculator.getHipAngle(pose);
    if (exerciseType == ExerciseType.pushup) {
      return hipAngle > 155 && hipAngle < 205;
    }
    if (exerciseType == ExerciseType.squat) {
      return hipAngle > 130;
    }
    return true;
  }

  void reset() {
    repCount = 0;
    currentPhase = RepPhase.up;
    isFormCorrect = true;
    lastRepTime = null;
    _angleHistory.clear();
    smoothnessScore = 100.0;
  }

  double getRepProgress(PoseLandmarks pose) {
    final angle = _getRelevantAngle(pose);
    final range = upAngleThreshold - downAngleThreshold;
    final progress = (upAngleThreshold - angle) / range;
    return progress.clamp(0.0, 1.0);
  }

  String getStatusMessage() {
    if (smoothnessScore < 70) {
      return 'Slow and steady! ⏳';
    }
    switch (currentPhase) {
      case RepPhase.up:
        return 'Ready';
      case RepPhase.down:
        return 'Push up!';
      default:
        return 'Keep going';
    }
  }
}
