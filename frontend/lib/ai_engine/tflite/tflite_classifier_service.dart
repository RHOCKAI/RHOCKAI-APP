import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../../core/config/feature_flags.dart';

/// Lifecycle state of the on-device TFLite model
enum ModelStatus {
  uninitialized,
  loading,
  ready,
  failed,
}

/// 🧠 On-Device TFLite Exercise Classifier & Form Scorer Service
///
/// Runs temporal sequence inference in a background Isolate.
/// Receives temporal feature windows from [LandmarkSequenceBuffer],
/// outputs exercise classification, confidence, and optional form score.
class TfliteClassifierService {
  static const String defaultModelPath =
      'assets/models/exercise_classifier_int8.tflite';

  /// Standard exercise classification labels matching Rhockai biomechanics engine
  static const List<String> defaultLabels = [
    'pushup',
    'squat',
    'plank',
    'lunge',
    'glute_bridge',
    'high_knees',
    'tricep_dip',
  ];

  Interpreter? _interpreter;
  bool _isInitialized = false;
  ModelStatus _status = ModelStatus.uninitialized;
  String _modelPath = defaultModelPath;
  List<String> _labels = defaultLabels;

  /// Current model lifecycle status
  ModelStatus get status => _status;

  /// Whether the TFLite interpreter is loaded and ready for inference
  bool get isReady =>
      _isInitialized &&
      _interpreter != null &&
      _status == ModelStatus.ready &&
      FeatureFlags.isEnabled('tflite_classifier');

  /// Active model asset path
  String get modelPath => _modelPath;

  /// Active classification labels
  List<String> get labels => List.unmodifiable(_labels);

  /// Native interpreter address for zero-overhead isolate communication
  int? get interpreterAddress => _interpreter?.address;

  /// Initializes the TFLite interpreter from Flutter assets.
  ///
  /// Configures hardware acceleration delegates (GPU / NNAPI / CoreML / XNNPACK)
  /// with graceful CPU fallback on failure.
  Future<bool> initialize({
    String modelPath = defaultModelPath,
    List<String>? labels,
    bool useGpu = false,
    bool useNnApi = false,
    bool useCoreMl = false,
    int numThreads = 2,
  }) async {
    if (!FeatureFlags.isEnabled('tflite_classifier')) {
      debugPrint('TfliteClassifierService: tflite_classifier flag is disabled.');
      _status = ModelStatus.uninitialized;
      return false;
    }

    _status = ModelStatus.loading;
    _modelPath = modelPath;
    if (labels != null && labels.isNotEmpty) {
      _labels = List<String>.from(labels);
    }

    try {
      final options = InterpreterOptions()..threads = numThreads;

      // Configure hardware delegates defensively
      _configureDelegates(
        options: options,
        useGpu: useGpu,
        useNnApi: useNnApi,
        useCoreMl: useCoreMl,
      );

      // Load interpreter from asset bundle
      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: options,
      );

      _isInitialized = true;
      _status = ModelStatus.ready;
      debugPrint('TfliteClassifierService: Initialized successfully with $_modelPath');
      return true;
    } catch (e) {
      debugPrint('TfliteClassifierService: Model load failed gracefully ($e). Falling back to rules.');
      _interpreter = null;
      _isInitialized = false;
      _status = ModelStatus.failed;
      return false;
    }
  }

  /// Hot-swaps the active model with a new model asset at runtime.
  ///
  /// Safely releases existing native resources and loads the new model without
  /// crashing the running workout pipeline.
  Future<bool> hotSwapModel({
    required String newModelPath,
    List<String>? labels,
    bool useGpu = false,
    bool useNnApi = false,
    bool useCoreMl = false,
    int numThreads = 2,
  }) async {
    debugPrint('TfliteClassifierService: Hot-swapping model to $newModelPath');
    dispose();
    return await initialize(
      modelPath: newModelPath,
      labels: labels,
      useGpu: useGpu,
      useNnApi: useNnApi,
      useCoreMl: useCoreMl,
      numThreads: numThreads,
    );
  }

  /// Configure platform-specific hardware acceleration delegates safely
  void _configureDelegates({
    required InterpreterOptions options,
    required bool useGpu,
    required bool useNnApi,
    required bool useCoreMl,
  }) {
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          if (useGpu) {
            try {
              options.addDelegate(GpuDelegateV2());
            } catch (e) {
              debugPrint('TfliteClassifierService: Android GPU delegate unavailable: $e');
            }
          }
        } else if (Platform.isIOS) {
          if (useCoreMl) {
            try {
              options.addDelegate(CoreMlDelegate());
            } catch (e) {
              debugPrint('TfliteClassifierService: iOS CoreML delegate unavailable: $e');
            }
          }
        }

        // Enable XNNPACK acceleration on CPU if supported
        try {
          options.addDelegate(XNNPackDelegate());
        } catch (_) {
          // XNNPack is optional
        }
      }
    } catch (e) {
      debugPrint('TfliteClassifierService: Delegate setup skipped: $e');
    }
  }

  /// Classifies a temporal sequence of features in a background Isolate.
  ///
  /// Returns null if service is not ready or feature flag is disabled.
  Future<Map<String, dynamic>?> classify(Object inputTensor) async {
    if (!isReady) {
      return null;
    }

    final args = <String, dynamic>{
      'interpreterAddress': interpreterAddress,
      'modelPath': _modelPath,
      'inputTensor': inputTensor,
      'labels': _labels,
    };

    try {
      return await compute(runInference, args);
    } catch (e) {
      debugPrint('TfliteClassifierService: Isolate inference error: $e');
      return null;
    }
  }

  /// Top-level or static isolate entry-point for TFLite inference.
  ///
  /// Accepts [args] map containing:
  /// - `inputTensor`: `Float32List` or `List<List<List<double>>>`
  /// - `interpreterAddress`: `int` address of an existing native interpreter (optional)
  /// - `modelPath`: `String` asset path to load if address not provided (optional)
  /// - `labels`: `List<String>` classification labels
  /// - `mockLogits`: `List<double>` optional for test verification
  ///
  /// Returns structured map:
  /// ```dart
  /// {
  ///   'exercise': String,     // e.g. "pushup"
  ///   'confidence': double,   // 0.0 - 1.0
  ///   'form_score': double?,  // optional 0.0 - 1.0
  ///   'raw_logits': List<double>?,
  /// }
  /// ```
  static Map<String, dynamic> runInference(Map<String, dynamic> args) {
    final List<String> labels = (args['labels'] as List?)?.cast<String>() ?? defaultLabels;
    final int numClasses = labels.length;

    // Support mock logits for testing and offline simulation
    if (args['mockLogits'] != null) {
      final List<double> mockLogits = (args['mockLogits'] as List).cast<double>();
      final probabilities = computeSoftmax(mockLogits);
      int bestIdx = 0;
      double maxProb = -1.0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          bestIdx = i;
        }
      }
      final exercise = bestIdx < labels.length ? labels[bestIdx] : 'unknown';
      final double? formScore = (args['mockFormScore'] as num?)?.toDouble();

      return {
        'exercise': exercise,
        'confidence': maxProb,
        'form_score': formScore,
        'raw_logits': mockLogits,
      };
    }

    final input = args['inputTensor'];
    if (input == null) {
      return {
        'exercise': 'unknown',
        'confidence': 0.0,
        'form_score': null,
        'raw_logits': null,
      };
    }

    // NOTE: Interpreter.fromAddress() creates a view into native memory owned by
    // the parent TfliteClassifierService. Do NOT close it here — that would
    // double-free the native resource. Lifecycle is managed by dispose().
    try {
      final Interpreter localInterpreter;
      if (args['interpreterAddress'] != null) {
        final int address = args['interpreterAddress'] as int;
        localInterpreter = Interpreter.fromAddress(address);
      } else {
        // fromAsset requires Flutter asset bundle bindings — not available in Isolate
        return {
          'exercise': 'unknown',
          'confidence': 0.0,
          'form_score': null,
          'raw_logits': null,
        };
      }

      // Prepare output tensors
      // Primary head: Classification logits [1, numClasses]
      final classificationOutput = List.generate(
        1,
        (_) => List<double>.filled(numClasses, 0.0),
      );

      final outputTensors = localInterpreter.getOutputTensors();
      double? formScore;

      if (outputTensors.length > 1) {
        // Multi-head model: head 0 = classification, head 1 = form score regression [1, 1]
        final formScoreOutput = List.generate(
          1,
          (_) => List<double>.filled(1, 0.0),
        );
        final outputs = <int, Object>{
          0: classificationOutput,
          1: formScoreOutput,
        };
        localInterpreter.runForMultipleInputs([input], outputs);

        final rawScore = formScoreOutput[0][0];
        formScore = rawScore.clamp(0.0, 1.0);
      } else {
        // Single head model
        localInterpreter.run(input, classificationOutput);
      }

      final rawLogits = classificationOutput[0];
      final probabilities = computeSoftmax(rawLogits);

      int bestIdx = 0;
      double maxProb = -1.0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          bestIdx = i;
        }
      }

      final exercise = bestIdx < labels.length ? labels[bestIdx] : 'unknown';

      return {
        'exercise': exercise,
        'confidence': maxProb,
        'form_score': formScore,
        'raw_logits': rawLogits,
      };
    } catch (e) {
      return {
        'exercise': 'unknown',
        'confidence': 0.0,
        'form_score': null,
        'raw_logits': null,
        'error': e.toString(),
      };
    }
    // No finally close — interpreter memory is owned by TfliteClassifierService.dispose()
  }

  /// Numerically stable Softmax calculation:
  /// sigma(z_i) = exp(z_i - max(z)) / sum(exp(z - max(z)))
  static List<double> computeSoftmax(List<double> logits) {
    if (logits.isEmpty) {
      return const [];
    }
    double maxVal = logits.reduce(max);
    List<double> expValues = logits.map((z) => exp(z - maxVal)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    if (sumExp == 0.0) {
      sumExp = 1.0;
    }
    return expValues.map((v) => v / sumExp).toList();
  }

  /// Closes the native TFLite interpreter and frees memory
  void dispose() {
    try {
      _interpreter?.close();
    } catch (_) {}
    _interpreter = null;
    _isInitialized = false;
    _status = ModelStatus.uninitialized;
  }
}
