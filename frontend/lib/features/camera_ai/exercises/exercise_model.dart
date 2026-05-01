import 'package:flutter/foundation.dart';
import '../pose/pose_landmark_model.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Exercise category classification
enum ExerciseCategory {
  upperBody,
  lowerBody,
  core,
  hiit,
  fullBody,
  cardio,
}

/// Difficulty level
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

/// Joint types for biomechanics
enum Joint {
  shoulder,
  elbow,
  wrist,
  hip,
  knee,
  ankle,
  neck,
  spine,
}

/// Rep detection type
enum RepType {
  /// Standard flexion-extension (push-ups, squats)
  flexionExtension,
  
  /// Hold-based (planks, wall sits)
  holdTime,
  
  /// Multi-phase sequence (burpees)
  multiPhase,
  
  /// Alternating sides (mountain climbers)
  alternating,
  
  /// Count-based (jumping jacks)
  count,
}

/// Angle definition for biomechanical analysis
class AngleDefinition {
  final String name;
  final PoseLandmarkType pointA;
  final PoseLandmarkType vertex;
  final PoseLandmarkType pointC;
  
  const AngleDefinition({
    required this.name,
    required this.pointA,
    required this.vertex,
    required this.pointC,
  });
}

/// Rep detection configuration
class RepDetectionConfig {
  final RepType type;
  final String primaryAngle;
  
  // Thresholds for flexion-extension
  final double? downThreshold;
  final double? upThreshold;
  final double? minAngle;
  final double? maxAngle;
  
  // For hold-time exercises
  final double? minHoldTime;
  
  // For multi-phase
  final List<RepPhase>? phases;
  
  const RepDetectionConfig({
    required this.type,
    required this.primaryAngle,
    this.downThreshold,
    this.upThreshold,
    this.minAngle,
    this.maxAngle,
    this.minHoldTime,
    this.phases,
  });
}

/// Phase definition for multi-phase exercises
class RepPhase {
  final String name;
  final Map<String, double> angleThresholds;
  final Duration? minDuration;
  
  const RepPhase({
    required this.name,
    required this.angleThresholds,
    this.minDuration,
  });
}

/// Form validation criterion
class FormCriterion {
  final String id;
  final String name;
  final String description;
  final double weight;
  final FormCheckFunction checkFunction;
  final String? feedbackMessage;
  
  const FormCriterion({
    required this.id,
    required this.name,
    required this.description,
    required this.weight,
    required this.checkFunction,
    this.feedbackMessage,
  });
}

/// Function type for form checking
typedef FormCheckFunction = bool Function(
  Map<String, double> angles,
  PoseLandmarks landmarks,
);

/// Exercise definition - complete specification for an exercise
@immutable
class ExerciseDefinition {
  final String id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final DifficultyLevel difficulty;
  
  // Biomechanics
  final List<Joint> primaryJoints;
  final List<PoseLandmarkType> landmarksUsed;
  final Map<String, AngleDefinition> angleDefinitions;
  
  // Rep detection
  final RepDetectionConfig repDetection;
  
  // Form validation
  final List<FormCriterion> formCriteria;
  
  // Scoring
  final double targetRepsPerSet;
  final double targetSets;
  
  // AI tracking
  final int aiReliability; // 1-10 scale
  final List<String> commonMistakes;
  final List<String> fatigueSignals;
  final List<String> injuryRisks;
  
  // Progression
  final String? previousExercise; // Easier variant
  final String? nextExercise; // Harder variant
  final double progressionThreshold; // Score needed to advance
  
  // Camera setup
  final CameraPosition recommendedCameraPosition;
  final double minConfidenceThreshold;
  
  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.primaryJoints,
    required this.landmarksUsed,
    required this.angleDefinitions,
    required this.repDetection,
    required this.formCriteria,
    this.targetRepsPerSet = 10,
    this.targetSets = 3,
    required this.aiReliability,
    this.commonMistakes = const [],
    this.fatigueSignals = const [],
    this.injuryRisks = const [],
    this.previousExercise,
    this.nextExercise,
    this.progressionThreshold = 85.0,
    this.recommendedCameraPosition = CameraPosition.sideFacing,
    this.minConfidenceThreshold = 0.7,
  });
  
  /// Get total weight of all form criteria
  double get totalWeight => formCriteria.fold(0.0, (sum, c) => sum + c.weight);
  
  /// Check if exercise is hold-based (planks, wall sits)
  bool get isHoldBased => repDetection.type == RepType.holdTime;
  
  /// Check if exercise requires symmetry tracking
  bool get requiresSymmetry {
    return landmarksUsed.any((l) => 
      l.name.contains('left') || l.name.contains('right')
    );
  }
}

/// Camera positioning for optimal tracking
enum CameraPosition {
  frontFacing,
  sideFacing,
  elevated45Degrees,
  groundLevel,
}

/// Form check result
class FormCheckResult {
  final double accuracy; // 0-100
  final List<CriterionResult> criteriaResults;
  final List<String> failedCriteria;
  final List<String> feedbackMessages;
  final bool passedAll;
  
  const FormCheckResult({
    required this.accuracy,
    required this.criteriaResults,
    required this.failedCriteria,
    required this.feedbackMessages,
    required this.passedAll,
  });
}

/// Individual criterion result
class CriterionResult {
  final String criterionId;
  final String name;
  final bool passed;
  final double weight;
  
  const CriterionResult({
    required this.criterionId,
    required this.name,
    required this.passed,
    required this.weight,
  });
}

/// Rep detection result
class RepDetectionResult {
  final int repCount;
  final RepState currentState;
  final double? currentAngle;
  final double? minAngleAchieved;
  final double? maxAngleAchieved;
  final Duration? holdDuration;
  final bool repJustCompleted;
  
  const RepDetectionResult({
    required this.repCount,
    required this.currentState,
    this.currentAngle,
    this.minAngleAchieved,
    this.maxAngleAchieved,
    this.holdDuration,
    this.repJustCompleted = false,
  });
}

/// Rep state for state machine
enum RepState {
  waiting,
  goingDown,
  goingUp,
  holding,
  phase1,
  phase2,
  phase3,
  phase4,
}
