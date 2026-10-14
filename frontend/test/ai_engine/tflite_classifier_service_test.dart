import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhockai/ai_engine/tflite/tflite_classifier_service.dart';
import 'package:rhockai/core/config/feature_flags.dart';

void main() {
  group('TfliteClassifierService Tests', () {
    late TfliteClassifierService service;

    setUp(() {
      FeatureFlags.resetToDefault();
      service = TfliteClassifierService();
    });

    tearDown(() {
      service.dispose();
    });

    test('Initial state is not ready', () {
      expect(service.isReady, isFalse);
      expect(service.interpreterAddress, isNull);
      expect(service.labels, contains('pushup'));
      expect(service.labels, contains('squat'));
    });

    test('classify returns null when not ready', () async {
      final dummyTensor = Float32List(45 * 18);
      final result = await service.classify(dummyTensor);
      expect(result, isNull);
    });

    test('classify returns null when feature flag is disabled', () async {
      FeatureFlags.setFlag('tflite_classifier', false);
      final dummyTensor = Float32List(45 * 18);
      final result = await service.classify(dummyTensor);
      expect(result, isNull);
    });

    test('computeSoftmax computes mathematically valid probabilities', () {
      final logits = [2.0, 1.0, 0.1];
      final probs = TfliteClassifierService.computeSoftmax(logits);

      expect(probs.length, equals(3));
      // Sum of probabilities must equal ~1.0
      final sum = probs.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-5));

      // Order preservation
      expect(probs[0], greaterThan(probs[1]));
      expect(probs[1], greaterThan(probs[2]));
    });

    test('computeSoftmax handles extreme values without NaN/overflow', () {
      final extremeLogits = [1000.0, 1001.0, 1002.0];
      final probs = TfliteClassifierService.computeSoftmax(extremeLogits);

      expect(probs.length, equals(3));
      expect(probs.every((p) => p.isFinite && !p.isNaN), isTrue);
      final sum = probs.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-5));
    });

    test('runInference with mockLogits returns highest probability exercise and confidence', () {
      final labels = ['pushup', 'squat', 'plank'];
      // Logit for squat is highest (index 1)
      final args = {
        'mockLogits': [1.0, 8.0, 0.5],
        'mockFormScore': 0.88,
        'labels': labels,
      };

      final result = TfliteClassifierService.runInference(args);

      expect(result['exercise'], equals('squat'));
      expect(result['confidence'], greaterThan(0.95));
      expect(result['form_score'], equals(0.88));
      expect(result['raw_logits'], equals([1.0, 8.0, 0.5]));
    });

    test('runInference handles missing input safely without throwing', () {
      final result = TfliteClassifierService.runInference({});

      expect(result['exercise'], equals('unknown'));
      expect(result['confidence'], equals(0.0));
      expect(result['form_score'], isNull);
      expect(result['raw_logits'], isNull);
    });

    test('runInference with invalid address fails gracefully with unknown exercise', () {
      final dummyTensor = Float32List(45 * 18);
      final args = {
        'interpreterAddress': 99999999, // Invalid pointer
        'inputTensor': dummyTensor,
        'labels': ['pushup', 'squat'],
      };

      // Must not crash the process; handles exception defensively
      final result = TfliteClassifierService.runInference(args);
      expect(result['exercise'], equals('unknown'));
      expect(result['confidence'], equals(0.0));
      expect(result.containsKey('error'), isTrue);
    });

    test('dispose resets state and frees resources cleanly', () {
      service.dispose();
      expect(service.isReady, isFalse);
      expect(service.interpreterAddress, isNull);
      expect(service.status, equals(ModelStatus.uninitialized));
    });

    test('Initial status is uninitialized', () {
      expect(service.status, equals(ModelStatus.uninitialized));
    });

    test('initialize returns false and sets status to failed on missing model', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final success = await service.initialize(modelPath: 'assets/models/non_existent.tflite');
      expect(success, isFalse);
      expect(service.isReady, isFalse);
      expect(service.status, equals(ModelStatus.failed));
    });

    test('initialize returns false and sets status to uninitialized when flag is disabled', () async {
      FeatureFlags.setFlag('tflite_classifier', false);
      final success = await service.initialize();
      expect(success, isFalse);
      expect(service.status, equals(ModelStatus.uninitialized));
    });

    test('hotSwapModel updates target model path and handles failure gracefully', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final success = await service.hotSwapModel(
        newModelPath: 'assets/models/specialized_squat_model.tflite',
        labels: ['squat', 'deep_squat'],
      );
      expect(success, isFalse);
      expect(service.modelPath, equals('assets/models/specialized_squat_model.tflite'));
      expect(service.labels, equals(['squat', 'deep_squat']));
      expect(service.status, equals(ModelStatus.failed));
    });
  });
}
