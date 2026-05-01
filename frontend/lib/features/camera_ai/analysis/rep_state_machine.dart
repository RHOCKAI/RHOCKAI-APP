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

/// Exercise types
enum ExerciseType {
  pushup,
  squat,
  plank,
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
      case ExerciseType.pushup:
        downAngleThreshold = ExerciseThresholds.pushupDownAngle;
        upAngleThreshold = ExerciseThresholds.pushupUpAngle;
        break;
      case ExerciseType.squat:
        downAngleThreshold = ExerciseThresholds.squatDownAngle;
        upAngleThreshold = ExerciseThresholds.squatUpAngle;
        break;
      case ExerciseType.plank:
        // Planks don't count reps
        downAngleThreshold = 0;
        upAngleThreshold = 0;
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
      case ExerciseType.pushup:
        return AngleCalculator.getAverageElbowAngle(pose);
      case ExerciseType.squat:
        return AngleCalculator.getAverageKneeAngle(pose);
      case ExerciseType.plank:
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
        // Check if back is relatively straight
        final hipAngleLeft = AngleCalculator.getHipAngle(pose, leftSide: true);
        final hipAngleRight = AngleCalculator.getHipAngle(pose, leftSide: false);
        final avgHipAngle = (hipAngleLeft + hipAngleRight) / 2;
        return avgHipAngle > 160 && avgHipAngle < 200;
        
      case ExerciseType.squat:
        // Check if chest is up (not leaning too far forward)
        final hipAngleLeft = AngleCalculator.getHipAngle(pose, leftSide: true);
        final hipAngleRight = AngleCalculator.getHipAngle(pose, leftSide: false);
        final avgHipAngle = (hipAngleLeft + hipAngleRight) / 2;
        return avgHipAngle > 140;
        
      case ExerciseType.plank:
        // Check if body is straight
        return AngleCalculator.isBodyStraight(
          pose,
          ExerciseThresholds.plankTolerance,
        );
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
