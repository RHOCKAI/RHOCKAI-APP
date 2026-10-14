import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/config/feature_flags.dart';
import '../../features/camera_ai/analysis/accuracy_calculator.dart';
import '../../features/camera_ai/analysis/exercise_classifier.dart';
import '../../features/camera_ai/pose/pose_landmark_model.dart';
import '../../features/camera_ai/services/voice_feedback_service.dart';
import 'landmark_sequence_buffer.dart';
import 'pose_feature_extractor.dart';
import 'tflite_classifier_service.dart';

/// 🔄 Pose Pipeline Coordinator
///
/// Orchestrates real-time integration between ML Kit Pose landmarks,
/// the temporal [LandmarkSequenceBuffer], and [TfliteClassifierService].
///
/// Ensures:
/// - 30 FPS non-blocking execution (zero frame drops on main thread)
/// - Confidence thresholding (confidence >= 0.82 triggers auto-detection)
/// - Fallback to heuristic [ExerciseClassifier] when confidence is low or flag is off
/// - Direct integration with [AccuracyCalculator] and [VoiceFeedbackService]
class PosePipelineCoordinator {
  static const double confidenceThreshold = 0.82;
  static const int defaultMaxFrames = 45;

  final PoseFeatureExtractor _featureExtractor = PoseFeatureExtractor();
  final LandmarkSequenceBuffer _buffer;
  final TfliteClassifierService _classifierService;
  final AccuracyCalculator? _accuracyCalculator;
  final VoiceFeedbackService? _voiceService;

  bool _isInferring = false;
  String? _lastAnnouncedExercise;
  DateTime? _lastAnnouncementTime;
  static const Duration _announcementDebounce = Duration(seconds: 4);

  /// Callback when an exercise is confirmed with high confidence (>= 0.82)
  void Function(String exercise, double confidence)? onExerciseDetected;

  /// Callback when a continuous form score is produced
  void Function(double formScore)? onFormScoreUpdated;

  PosePipelineCoordinator({
    LandmarkSequenceBuffer? buffer,
    TfliteClassifierService? classifierService,
    AccuracyCalculator? accuracyCalculator,
    VoiceFeedbackService? voiceService,
    this.onExerciseDetected,
    this.onFormScoreUpdated,
  })  : _buffer = buffer ?? LandmarkSequenceBuffer(maxFrames: defaultMaxFrames),
        _classifierService = classifierService ?? TfliteClassifierService(),
        _accuracyCalculator = accuracyCalculator,
        _voiceService = voiceService;

  bool get isReady => _classifierService.isReady;
  bool get isBufferReady => _buffer.isReady;
  ModelStatus get modelStatus => _classifierService.status;

  /// Loads and prepares the TFLite model
  Future<bool> initializeModel({
    String? modelPath,
    List<String>? labels,
    bool useGpu = false,
    bool useNnApi = false,
    bool useCoreMl = false,
    int numThreads = 2,
  }) async {
    return await _classifierService.initialize(
      modelPath: modelPath ?? TfliteClassifierService.defaultModelPath,
      labels: labels,
      useGpu: useGpu,
      useNnApi: useNnApi,
      useCoreMl: useCoreMl,
      numThreads: numThreads,
    );
  }

  /// Hot-swaps the active classification model at runtime
  Future<bool> hotSwapModel({
    required String newModelPath,
    List<String>? labels,
    bool useGpu = false,
    bool useNnApi = false,
    bool useCoreMl = false,
    int numThreads = 2,
  }) async {
    reset();
    return await _classifierService.hotSwapModel(
      newModelPath: newModelPath,
      labels: labels,
      useGpu: useGpu,
      useNnApi: useNnApi,
      useCoreMl: useCoreMl,
      numThreads: numThreads,
    );
  }

  /// Ingests a new smoothed pose frame into the pipeline
  Future<void> processPose(PoseLandmarks pose, {String? activeExercise}) async {
    // 1. Extract 18D kinematic feature vector
    final features = _featureExtractor.extractFeatures(pose);

    // 2. Feed into sliding window sequence buffer
    _buffer.add(features);

    // 3. Fallback check: if TFLite is not enabled or not ready, use rule-based classifier
    if (!FeatureFlags.isEnabled('tflite_classifier') || !_classifierService.isReady) {
      _runRuleBasedFallback(pose, activeExercise);
      return;
    }

    // 4. When buffer is full and not currently inferring in Isolate
    if (_buffer.isReady && !_isInferring) {
      final inputTensor = _buffer.toInputTensor(featureDim: PoseFeatureExtractor.featureDim);
      if (inputTensor == null) {
        return;
      }

      _isInferring = true;

      unawaited(
        _classifierService.classify(inputTensor).then((result) {
          _isInferring = false;
          if (result != null) {
            _handleInferenceResult(result, pose, activeExercise);
          }
        }).catchError((e) {
          _isInferring = false;
          debugPrint('PosePipelineCoordinator: Classification error: $e');
        }),
      );
    }
  }

  /// Handles result produced by background Isolate inference
  void _handleInferenceResult(
    Map<String, dynamic> result,
    PoseLandmarks pose,
    String? activeExercise,
  ) {
    final String exercise = result['exercise'] as String? ?? 'unknown';
    final double confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    final double? formScore = (result['form_score'] as num?)?.toDouble();

    // Ingest form score into AccuracyCalculator
    if (formScore != null) {
      _accuracyCalculator?.feedTfliteFormScore(formScore);
      onFormScoreUpdated?.call(formScore);
    }

    // Threshold logic: If confidence >= 0.82 -> auto-set exercise
    if (confidence >= confidenceThreshold && exercise != 'unknown') {
      _confirmExercise(exercise, confidence, activeExercise);
    } else {
      // Fallback to rule-based pattern matcher if confidence is low
      _runRuleBasedFallback(pose, activeExercise);
    }
  }

  /// Confirms detected exercise, triggers callbacks and voice cues
  void _confirmExercise(String exercise, double confidence, String? activeExercise) {
    onExerciseDetected?.call(exercise, confidence);

    // Voice announcement (debounced)
    final now = DateTime.now();
    final bool canAnnounce = _lastAnnouncementTime == null ||
        now.difference(_lastAnnouncementTime!) > _announcementDebounce;

    if (canAnnounce && exercise != _lastAnnouncedExercise && exercise != activeExercise) {
      _lastAnnouncedExercise = exercise;
      _lastAnnouncementTime = now;

      final formattedName = _formatExerciseName(exercise);
      _voiceService?.announceDetectedExercise(formattedName);
    }
  }

  /// Rule-based fallback classifier
  void _runRuleBasedFallback(PoseLandmarks pose, String? activeExercise) {
    final ruleDetected = ExerciseClassifier.detectExercise(pose);
    if (ruleDetected != null && ruleDetected != activeExercise) {
      // Rule based detected with certainty
      _confirmExercise(ruleDetected, 0.80, activeExercise);
    }
  }

  String _formatExerciseName(String id) {
    switch (id) {
      case 'pushup':
        return 'Push-ups';
      case 'squat':
        return 'Squats';
      case 'plank':
        return 'Plank';
      case 'lunge':
        return 'Lunges';
      case 'high_knees':
        return 'High Knees';
      case 'glute_bridge':
        return 'Glute Bridges';
      case 'tricep_dip':
        return 'Tricep Dips';
      default:
        return id.replaceAll('_', ' ');
    }
  }

  /// Clear temporal buffers and state (e.g. on set finish or workout pause)
  void reset() {
    _buffer.clear();
    _featureExtractor.reset();
    _isInferring = false;
  }

  /// Disposes coordinator resources
  void dispose() {
    reset();
    _classifierService.dispose();
  }
}
