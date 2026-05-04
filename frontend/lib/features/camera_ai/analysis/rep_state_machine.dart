import '../pose/pose_landmark_model.dart';
import 'angle_calculator.dart';
import 'tempo_analyzer.dart';
import '../../../core/constants/exercises.dart';

/// Rep detection phases
enum RepPhase {
  up,         // Starting position (arms/legs extended)
  down,       // Bottom position (arms/legs bent)
  transition, // Moving between positions
}

/// Exercise types supported by AI rep counting
enum ExerciseType {
  // Beginner
  pushup,
  squat,
  plank,
  gluteBridge,
  inchworm,
  highKnees,
  // Intermediate
  lunge,
  tricepDip,
  mountainClimber,
  sidePlank,
  reverseLunge,
  pikePushup,
  sumoSquat,
  // Advanced
  pistolSquat,
  diamondPushup,
  archerPushup,
  jumpSquat,
  burpee,
  singleLegDeadlift,
  spidermanPushup,
}

/// Rep counting state machine
class RepStateMachine {
  final ExerciseType exerciseType;
  
  RepPhase currentPhase = RepPhase.up;
  int repCount = 0;
  bool isFormCorrect = true;
  double lastTempoScore = 0.0;
  String tempoFeedback = '';
  
  late double downAngleThreshold;
  late double upAngleThreshold;
  
  late TempoAnalyzer _tempoAnalyzer;
  
  DateTime? lastRepTime;
  
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
      // ── Elbow-angle exercises ─────────────────────────────
      case ExerciseType.pushup:
      case ExerciseType.diamondPushup:
      case ExerciseType.archerPushup:
      case ExerciseType.spidermanPushup:
        downAngleThreshold = ExerciseThresholds.pushupDownAngle;   // 90°
        upAngleThreshold   = ExerciseThresholds.pushupUpAngle;     // 160°
        break;
      case ExerciseType.tricepDip:
      case ExerciseType.pikePushup:
        downAngleThreshold = 85.0;
        upAngleThreshold   = 155.0;
        break;
      case ExerciseType.inchworm:
      case ExerciseType.mountainClimber:
      case ExerciseType.burpee:
        // Uses elbow/hip combo; track elbow as primary
        downAngleThreshold = ExerciseThresholds.pushupDownAngle;
        upAngleThreshold   = ExerciseThresholds.pushupUpAngle;
        break;
      // ── Knee-angle exercises ──────────────────────────────
      case ExerciseType.squat:
      case ExerciseType.sumoSquat:
        downAngleThreshold = ExerciseThresholds.squatDownAngle;    // 90°
        upAngleThreshold   = ExerciseThresholds.squatUpAngle;      // 170°
        break;
      case ExerciseType.lunge:
      case ExerciseType.reverseLunge:
      case ExerciseType.pistolSquat:
        downAngleThreshold = 85.0;
        upAngleThreshold   = 165.0;
        break;
      case ExerciseType.jumpSquat:
        downAngleThreshold = 100.0;
        upAngleThreshold   = 165.0;
        break;
      case ExerciseType.highKnees:
        downAngleThreshold = 80.0;  // knee raised high
        upAngleThreshold   = 160.0; // knee lowered
        break;
      // ── Hip-angle exercises (holds / hinge) ───────────────
      case ExerciseType.plank:
      case ExerciseType.sidePlank:
        downAngleThreshold = 0;
        upAngleThreshold   = 0;
        break;
      case ExerciseType.gluteBridge:
        downAngleThreshold = 100.0;  // hips near floor
        upAngleThreshold   = 155.0;  // hips extended
        break;
      case ExerciseType.singleLegDeadlift:
        downAngleThreshold = 90.0;   // hip hinged forward
        upAngleThreshold   = 160.0;  // standing tall
        break;
    }
  }
  
  /// Process pose and update rep state
  /// Returns true if a new rep was completed
  bool processPose(PoseLandmarks pose) {
    final angle = _getRelevantAngle(pose);
    
    // State machine logic
    switch (currentPhase) {
      case RepPhase.up:
        // Check if going down
        if (angle < downAngleThreshold) {
          currentPhase = RepPhase.down;
          _tempoAnalyzer.recordPhaseStart(); // Start Eccentric
        }
        break;
        
      case RepPhase.down:
        // Check if coming back up
        if (angle > upAngleThreshold) {
          // Rep completed!
          if (_isValidRep()) {
            repCount++;
            
            // Finalize durations (Concentric finished)
            final concentricDuration = _tempoAnalyzer.completePhase();
            // In a real sophisticated model, we'd track Isometric separately.
            // For now: Eccentric = duration from Up to Down, 
            // Concentric = duration from Down to Up.
            _tempoAnalyzer.updateRepDurations(
              1.5, // Mocking eccentric for now until I add more transition points
              0.2, // Mocking isometric
              concentricDuration
            );
            
            lastTempoScore = _tempoAnalyzer.calculateScore();
            tempoFeedback = _tempoAnalyzer.getTempoFeedback();
            
            lastRepTime = DateTime.now();
            currentPhase = RepPhase.up;
            return true; // New rep completed
          }
        }
        break;
        
      case RepPhase.transition:
        // Optional: Handle transition state for smoother detection
        break;
    }
    
    // Update form correctness
    isFormCorrect = _checkBasicForm(pose);
    
    return false; // No new rep
  }
  
  /// Get the relevant angle based on exercise type
  double _getRelevantAngle(PoseLandmarks pose) {
    switch (exerciseType) {
      // Elbow-driven
      case ExerciseType.pushup:
      case ExerciseType.diamondPushup:
      case ExerciseType.archerPushup:
      case ExerciseType.spidermanPushup:
      case ExerciseType.tricepDip:
      case ExerciseType.pikePushup:
      case ExerciseType.inchworm:
      case ExerciseType.mountainClimber:
      case ExerciseType.burpee:
        return AngleCalculator.getAverageElbowAngle(pose);
      // Knee-driven
      case ExerciseType.squat:
      case ExerciseType.sumoSquat:
      case ExerciseType.lunge:
      case ExerciseType.reverseLunge:
      case ExerciseType.pistolSquat:
      case ExerciseType.jumpSquat:
      case ExerciseType.highKnees:
        return AngleCalculator.getAverageKneeAngle(pose);
      // Hip-angle driven
      case ExerciseType.plank:
      case ExerciseType.sidePlank:
      case ExerciseType.gluteBridge:
      case ExerciseType.singleLegDeadlift:
        return AngleCalculator.getHipAngle(pose);
    }
  }
  
  /// Check if rep timing is valid (not too fast or slow)
  bool _isValidRep() {
    if (lastRepTime == null) {
      return true;
    }
    
    final timeSinceLastRep = DateTime.now().difference(lastRepTime!);
    
    return timeSinceLastRep.inMilliseconds >= ExerciseThresholds.minRepDurationMs &&
           timeSinceLastRep.inMilliseconds <= ExerciseThresholds.maxRepDurationMs;
  }
  
  /// Basic form check (detailed checking done in FormChecker)
  bool _checkBasicForm(PoseLandmarks pose) {
    switch (exerciseType) {
      case ExerciseType.pushup:
      case ExerciseType.diamondPushup:
      case ExerciseType.archerPushup:
      case ExerciseType.spidermanPushup:
      case ExerciseType.tricepDip:
      case ExerciseType.pikePushup:
      case ExerciseType.inchworm:
      case ExerciseType.mountainClimber:
      case ExerciseType.burpee:
        final hipL = AngleCalculator.getHipAngle(pose, leftSide: true);
        final hipR = AngleCalculator.getHipAngle(pose, leftSide: false);
        final avg = (hipL + hipR) / 2;
        return avg > 160 && avg < 200;
      case ExerciseType.squat:
      case ExerciseType.sumoSquat:
      case ExerciseType.lunge:
      case ExerciseType.reverseLunge:
      case ExerciseType.pistolSquat:
      case ExerciseType.jumpSquat:
      case ExerciseType.highKnees:
        final hipAngleL = AngleCalculator.getHipAngle(pose, leftSide: true);
        final hipAngleR = AngleCalculator.getHipAngle(pose, leftSide: false);
        return (hipAngleL + hipAngleR) / 2 > 140;
      case ExerciseType.plank:
      case ExerciseType.sidePlank:
        return AngleCalculator.isBodyStraight(
          pose,
          ExerciseThresholds.plankTolerance,
        );
      case ExerciseType.gluteBridge:
      case ExerciseType.singleLegDeadlift:
        return true; // Hip extension — basic check passes
    }
  }
  
  /// Reset the state machine
  void reset() {
    repCount = 0;
    currentPhase = RepPhase.up;
    isFormCorrect = true;
    lastRepTime = null;
  }
  
  /// Get current rep progress (0.0 to 1.0)
  double getRepProgress(PoseLandmarks pose) {
    final angle = _getRelevantAngle(pose);
    
    // Calculate progress based on angle range
    final range = upAngleThreshold - downAngleThreshold;
    final progress = (angle - downAngleThreshold) / range;
    
    return progress.clamp(0.0, 1.0);
  }
  
  /// Get status message
  String getStatusMessage() {
    switch (currentPhase) {
      case RepPhase.up:
        return 'Ready';
      case RepPhase.down:
        return 'Push up!';
      case RepPhase.transition:
        return 'Keep going';
    }
  }
}
