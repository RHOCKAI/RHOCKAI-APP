import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_model.dart';
import 'form_scorer.dart';

/// Example exercise definitions
/// This demonstrates how to define exercises using the framework

/// SQUAT - Complete definition
final squatExercise = ExerciseDefinition(
  id: 'bodyweight_squat',
  name: 'Bodyweight Squat',
  description: 'Stand with feet shoulder-width apart, lower body by bending knees and hips',
  category: ExerciseCategory.lowerBody,
  difficulty: DifficultyLevel.beginner,
  
  primaryJoints: const [Joint.hip, Joint.knee, Joint.ankle],
  landmarksUsed: const [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ],
  
  angleDefinitions: const {
    'knee': AngleDefinition(
      name: 'Knee Flexion',
      pointA: PoseLandmarkType.leftHip,
      vertex: PoseLandmarkType.leftKnee,
      pointC: PoseLandmarkType.leftAnkle,
    ),
    'hip': AngleDefinition(
      name: 'Hip Flexion',
      pointA: PoseLandmarkType.leftShoulder,
      vertex: PoseLandmarkType.leftHip,
      pointC: PoseLandmarkType.leftKnee,
    ),
  },
  
  repDetection: const RepDetectionConfig(
    type: RepType.flexionExtension,
    primaryAngle: 'knee',
    downThreshold: 100, // Knee bent (parallel or below)
    upThreshold: 160,   // Knee nearly straight
    minAngle: 70,       // Deepest position
    maxAngle: 175,      // Standing position
  ),
  
  formCriteria: [
    const FormCriterion(
      id: 'knees_not_past_toes',
      name: 'Knees Behind Toes',
      description: 'Knees should not extend past toes',
      weight: 0.3,
      checkFunction: FormCheckFunctions.kneesNotPastToes,
      feedbackMessage: 'Keep knees behind toes',
    ),
    FormCriterion(
      id: 'back_straight',
      name: 'Back Straight',
      description: 'Maintain neutral spine',
      weight: 0.3,
      checkFunction: (angles, landmarks) {
        // Check torso angle
        final hipAngle = angles['hip'];
        if (hipAngle == null) {
          return false;
        }
        // Torso should stay relatively upright
        return hipAngle > 45;
      },
      feedbackMessage: 'Keep chest up and back straight',
    ),
    const FormCriterion(
      id: 'depth',
      name: 'Proper Depth',
      description: 'Squat to parallel (90°) or below',
      weight: 0.2,
      checkFunction: FormCheckFunctions.squatDepth,
      feedbackMessage: 'Go deeper - hips below knees',
    ),
    const FormCriterion(
      id: 'knee_alignment',
      name: 'Knee Tracking',
      description: 'Knees track over toes (not caving in)',
      weight: 0.2,
      checkFunction: FormCheckFunctions.kneeAlignment,
      feedbackMessage: 'Keep knees aligned with toes',
    ),
  ],
  
  targetRepsPerSet: 12,
  targetSets: 3,
  
  aiReliability: 9,
  
  commonMistakes: const [
    'Knees caving inward (valgus)',
    'Excessive forward lean',
    'Heels lifting off ground',
    'Not reaching parallel depth',
  ],
  
  fatigueSignals: const [
    'Knees starting to cave inward',
    'Loss of depth (shallow squats)',
    'Increased forward lean',
    'Knee wobble or instability',
  ],
  
  injuryRisks: const [
    'Knee valgus (inward collapse) - 🔴 HIGH RISK',
    'Excessive spinal flexion - ⚠️ MEDIUM RISK',
  ],
  
  previousExercise: 'assisted_squat',
  nextExercise: 'jump_squat',
  progressionThreshold: 85.0,
  
  recommendedCameraPosition: CameraPosition.sideFacing,
  minConfidenceThreshold: 0.7,
);

/// PLANK - Hold-based exercise
const plankExercise = ExerciseDefinition(
  id: 'forearm_plank',
  name: 'Forearm Plank',
  description: 'Hold body in straight line on forearms and toes',
  category: ExerciseCategory.core,
  difficulty: DifficultyLevel.beginner,
  
  primaryJoints: [Joint.shoulder, Joint.hip, Joint.spine],
  landmarksUsed: [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ],
  
  angleDefinitions: {
    'body_line': AngleDefinition(
      name: 'Body Alignment',
      pointA: PoseLandmarkType.leftShoulder,
      vertex: PoseLandmarkType.leftHip,
      pointC: PoseLandmarkType.leftAnkle,
    ),
  },
  
  repDetection: RepDetectionConfig(
    type: RepType.holdTime,
    primaryAngle: 'body_line',
    minHoldTime: 30.0, // 30 seconds minimum
  ),
  
  formCriteria: [
    FormCriterion(
      id: 'back_straight',
      name: 'Straight Body Line',
      description: 'Body forms straight line from head to heels',
      weight: 0.4,
      checkFunction: FormCheckFunctions.backStraight,
      feedbackMessage: 'Keep body in straight line - don\'t sag or pike',
    ),
    FormCriterion(
      id: 'core_engaged',
      name: 'Core Engaged',
      description: 'Core tight, preventing hip sag',
      weight: 0.3,
      checkFunction: FormCheckFunctions.coreEngaged,
      feedbackMessage: 'Engage your core - pull belly button to spine',
    ),
    FormCriterion(
      id: 'hip_alignment',
      name: 'Hips Level',
      description: 'Hips level with shoulders and ankles',
      weight: 0.2,
      checkFunction: FormCheckFunctions.hipAlignment,
      feedbackMessage: 'Keep hips level',
    ),
    FormCriterion(
      id: 'shoulder_position',
      name: 'Shoulders Stable',
      description: 'Shoulders directly over elbows',
      weight: 0.1,
      checkFunction: FormCheckFunctions.shoulderPosition,
      feedbackMessage: 'Stack shoulders over elbows',
    ),
  ],
  
  targetRepsPerSet: 30, // 30 seconds
  targetSets: 3,
  
  aiReliability: 8,
  
  commonMistakes: [
    'Hips sagging (most common)',
    'Hips too high (pike position)',
    'Head dropping',
    'Not breathing',
  ],
  
  fatigueSignals: [
    'Hip sag increasing',
    'Shoulders shaking',
    'Breaking hold early',
  ],
  
  injuryRisks: [
    'Lower back strain from excessive sag - ⚠️ MEDIUM RISK',
    'Shoulder strain - 🟡 LOW RISK',
  ],
  
  previousExercise: 'knee_plank',
  nextExercise: 'plank_shoulder_taps',
  progressionThreshold: 80.0,
  
  recommendedCameraPosition: CameraPosition.sideFacing,
  minConfidenceThreshold: 0.7,
);

/// BURPEE - Multi-phase exercise
final burpeeExercise = ExerciseDefinition(
  id: 'burpee',
  name: 'Burpee',
  description: 'Squat, plank, push-up, jump sequence',
  category: ExerciseCategory.hiit,
  difficulty: DifficultyLevel.intermediate,
  
  primaryJoints: const [Joint.hip, Joint.knee, Joint.shoulder, Joint.elbow],
  landmarksUsed: const [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ],
  
  angleDefinitions: const {
    'knee': AngleDefinition(
      name: 'Knee',
      pointA: PoseLandmarkType.leftHip,
      vertex: PoseLandmarkType.leftKnee,
      pointC: PoseLandmarkType.leftAnkle,
    ),
    'elbow': AngleDefinition(
      name: 'Elbow',
      pointA: PoseLandmarkType.leftShoulder,
      vertex: PoseLandmarkType.leftElbow,
      pointC: PoseLandmarkType.leftWrist,
    ),
  },
  
  repDetection: const RepDetectionConfig(
    type: RepType.multiPhase,
    primaryAngle: 'knee',
    phases: [
      RepPhase(
        name: 'Squat Down',
        angleThresholds: {'knee': 90},
        minDuration: Duration(milliseconds: 300),
      ),
      RepPhase(
        name: 'Plank Position',
        angleThresholds: {'knee': 160, 'elbow': 160},
        minDuration: Duration(milliseconds: 200),
      ),
      RepPhase(
        name: 'Push-Up',
        angleThresholds: {'elbow': 90},
        minDuration: Duration(milliseconds: 400),
      ),
      RepPhase(
        name: 'Jump',
        angleThresholds: {'knee': 160},
        minDuration: Duration(milliseconds: 300),
      ),
    ],
  ),
  
  formCriteria: [
    FormCriterion(
      id: 'full_sequence',
      name: 'Complete All Phases',
      description: 'Perform full burpee sequence',
      weight: 0.5,
      checkFunction: (angles, landmarks) => true, // Handled by phase detection
      feedbackMessage: 'Complete all phases of burpee',
    ),
    const FormCriterion(
      id: 'plank_form',
      name: 'Good Plank Position',
      description: 'Maintain plank in middle of burpee',
      weight: 0.3,
      checkFunction: FormCheckFunctions.backStraight,
      feedbackMessage: 'Keep back straight in plank',
    ),
    FormCriterion(
      id: 'explosive_jump',
      name: 'Explosive Jump',
      description: 'Full extension on jump',
      weight: 0.2,
      checkFunction: (angles, landmarks) {
        final kneeAngle = angles['knee'];
        return kneeAngle != null && kneeAngle > 150;
      },
      feedbackMessage: 'Jump explosively',
    ),
  ],
  
  targetRepsPerSet: 10,
  targetSets: 3,
  
  aiReliability: 7, // Lower due to complexity
  
  commonMistakes: const [
    'Skipping the push-up',
    'Not jumping high enough',
    'Poor plank position',
    'Rushing through phases',
  ],
  
  fatigueSignals: const [
    'Skipping push-up phase',
    'Shallow jumps',
    'Breaking form in plank',
    'Significantly slower pace',
  ],
  
  injuryRisks: const [
    'Wrist strain from impact - ⚠️ MEDIUM RISK',
    'Lower back strain - ⚠️ MEDIUM RISK',
    'Knee impact from jumping - 🟡 LOW RISK',
  ],
  
  previousExercise: 'squat_thrust',
  nextExercise: 'burpee_push_up_combo',
  progressionThreshold: 80.0,
  
  recommendedCameraPosition: CameraPosition.sideFacing,
  minConfidenceThreshold: 0.6, // Lower due to fast movement
);
