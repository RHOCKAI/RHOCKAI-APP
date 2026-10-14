import 'package:flutter_test/flutter_test.dart';
import 'package:rhockai/ai_engine/tflite/landmark_sequence_buffer.dart';
import 'package:rhockai/ai_engine/tflite/pose_feature_extractor.dart';
import 'package:rhockai/ai_engine/tflite/pose_pipeline_coordinator.dart';
import 'package:rhockai/core/config/feature_flags.dart';
import 'package:rhockai/features/camera_ai/analysis/accuracy_calculator.dart';
import 'package:rhockai/features/camera_ai/pose/pose_landmark_model.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as mlkit;

PoseLandmarks createMockPose({
  double elbowAngle = 90.0,
  double kneeAngle = 90.0,
  double hipAngle = 180.0,
  bool horizontal = false,
}) {
  final map = <mlkit.PoseLandmarkType, PoseLandmark>{};

  // Build standard landmarks
  if (horizontal) {
    // Plank / Push-up position: shoulders and hips roughly horizontal
    map[mlkit.PoseLandmarkType.leftShoulder] = PoseLandmark(x: 0.2, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightShoulder] = PoseLandmark(x: 0.2, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftElbow] = PoseLandmark(x: 0.2, y: 0.7, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightElbow] = PoseLandmark(x: 0.2, y: 0.7, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftWrist] = PoseLandmark(x: 0.2, y: 0.9, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightWrist] = PoseLandmark(x: 0.2, y: 0.9, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftHip] = PoseLandmark(x: 0.5, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightHip] = PoseLandmark(x: 0.5, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftKnee] = PoseLandmark(x: 0.7, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightKnee] = PoseLandmark(x: 0.7, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftAnkle] = PoseLandmark(x: 0.9, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightAnkle] = PoseLandmark(x: 0.9, y: 0.5, z: 0.0, likelihood: 0.95);
  } else {
    // Standing upright position (Squats / Idle)
    map[mlkit.PoseLandmarkType.leftShoulder] = PoseLandmark(x: 0.4, y: 0.2, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightShoulder] = PoseLandmark(x: 0.6, y: 0.2, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftElbow] = PoseLandmark(x: 0.35, y: 0.4, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightElbow] = PoseLandmark(x: 0.65, y: 0.4, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftWrist] = PoseLandmark(x: 0.35, y: 0.6, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightWrist] = PoseLandmark(x: 0.65, y: 0.6, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftHip] = PoseLandmark(x: 0.45, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightHip] = PoseLandmark(x: 0.55, y: 0.5, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftKnee] = PoseLandmark(x: 0.45, y: 0.75, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightKnee] = PoseLandmark(x: 0.55, y: 0.75, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.leftAnkle] = PoseLandmark(x: 0.45, y: 0.95, z: 0.0, likelihood: 0.95);
    map[mlkit.PoseLandmarkType.rightAnkle] = PoseLandmark(x: 0.55, y: 0.95, z: 0.0, likelihood: 0.95);
  }

  return PoseLandmarks(landmarks: map);
}

void main() {
  group('PosePipelineCoordinator Tests', () {
    late PoseFeatureExtractor extractor;
    late LandmarkSequenceBuffer buffer;
    late AccuracyCalculator accuracyCalculator;
    late PosePipelineCoordinator coordinator;

    setUp(() {
      FeatureFlags.resetToDefault();
      extractor = PoseFeatureExtractor();
      buffer = LandmarkSequenceBuffer(maxFrames: 5);
      accuracyCalculator = AccuracyCalculator();
      coordinator = PosePipelineCoordinator(
        buffer: buffer,
        accuracyCalculator: accuracyCalculator,
      );
    });

    tearDown(() {
      coordinator.dispose();
      accuracyCalculator.dispose();
    });

    test('PoseFeatureExtractor produces exactly 18 finite normalized features', () {
      final mockPose = createMockPose();
      final features = extractor.extractFeatures(mockPose);

      expect(features.length, equals(18));
      expect(features.every((f) => f.isFinite && !f.isNaN), isTrue);

      // First 9 are angles normalized to [0, 1]
      for (int i = 0; i < 9; i++) {
        expect(features[i], inInclusiveRange(0.0, 1.0));
      }
    });

    test('processPose feeds into LandmarkSequenceBuffer until ready', () async {
      final mockPose = createMockPose();

      expect(coordinator.isBufferReady, isFalse);

      for (int i = 0; i < 5; i++) {
        await coordinator.processPose(mockPose);
      }

      expect(coordinator.isBufferReady, isTrue);
    });

    test('AccuracyCalculator integrates TFLite form score properly', () {
      accuracyCalculator.feedTfliteFormScore(0.90);
      expect(accuracyCalculator.latestTfliteFormScore, equals(0.90));

      final repAcc = accuracyCalculator.calculateRepAccuracy(
        targetDepth: 90.0,
        achievedDepth: 90.0,
      );

      // Rep accuracy should be computed and incorporate the ML form score
      expect(repAcc, greaterThan(70.0));
      // Form score should reset after consumption
      expect(accuracyCalculator.latestTfliteFormScore, isNull);
    });

    test('Fallback to rule-based classifier when TFLite flag is disabled', () async {
      FeatureFlags.setFlag('tflite_classifier', false);

      String? detectedExercise;
      double? detectedConfidence;

      final testCoordinator = PosePipelineCoordinator(
        buffer: LandmarkSequenceBuffer(maxFrames: 2),
        onExerciseDetected: (exercise, conf) {
          detectedExercise = exercise;
          detectedConfidence = conf;
        },
      );

      // Provide horizontal plank pose
      final plankPose = createMockPose(horizontal: true);
      await testCoordinator.processPose(plankPose, activeExercise: 'idle');

      // Rule-based fallback should trigger for clear plank pattern
      expect(detectedExercise, equals('plank'));
      expect(detectedConfidence, equals(0.80));

      testCoordinator.dispose();
    });

    test('Reset clears buffer and velocity history cleanly', () async {
      final mockPose = createMockPose();
      for (int i = 0; i < 5; i++) {
        await coordinator.processPose(mockPose);
      }
      expect(coordinator.isBufferReady, isTrue);

      coordinator.reset();
      expect(coordinator.isBufferReady, isFalse);
    });
  });
}
