import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhockai/ai_engine/tflite/landmark_sequence_buffer.dart';

void main() {
  group('LandmarkSequenceBuffer Tests', () {
    test('Initial state is empty and not ready', () {
      final buffer = LandmarkSequenceBuffer(maxFrames: 5);
      expect(buffer.isReady, isFalse);
      expect(buffer.currentFrames, equals(0));
      expect(buffer.toInputTensor(featureDim: 4), isNull);
    });

    test('Becomes ready when filled with maxFrames', () {
      final buffer = LandmarkSequenceBuffer(maxFrames: 3);

      buffer.add([1.0, 2.0]);
      expect(buffer.isReady, isFalse);
      expect(buffer.currentFrames, equals(1));

      buffer.add([3.0, 4.0]);
      expect(buffer.isReady, isFalse);
      expect(buffer.currentFrames, equals(2));

      buffer.add([5.0, 6.0]);
      expect(buffer.isReady, isTrue);
      expect(buffer.currentFrames, equals(3));
    });

    test('Sliding window drops oldest frame when full', () {
      final buffer = LandmarkSequenceBuffer(maxFrames: 2);

      buffer.add([10.0, 20.0]);
      buffer.add([30.0, 40.0]);
      expect(buffer.isReady, isTrue);

      // Add third frame -> drops [10.0, 20.0]
      buffer.add([50.0, 60.0]);
      expect(buffer.currentFrames, equals(2));

      final tensor = buffer.toInputTensor(featureDim: 2);
      expect(tensor, isNotNull);
      expect(tensor!.length, equals(4)); // 2 frames * 2 features
      expect(tensor[0], equals(30.0));
      expect(tensor[1], equals(40.0));
      expect(tensor[2], equals(50.0));
      expect(tensor[3], equals(60.0));
    });

    test('Produces correctly shaped Float32List with zero-padding', () {
      final buffer = LandmarkSequenceBuffer(maxFrames: 2);

      buffer.add([1.0, 2.0]);
      buffer.add([3.0, 4.0]);

      // Feature dimension 4: expects 2 features padded with 2 zeros per frame
      final tensor = buffer.toInputTensor(featureDim: 4);
      expect(tensor, isNotNull);
      expect(tensor!.length, equals(8)); // 1 * 2 * 4
      expect(tensor, equals(Float32List.fromList([1.0, 2.0, 0.0, 0.0, 3.0, 4.0, 0.0, 0.0])));
    });

    test('toNestedTensor returns shape [1, maxFrames, featureDim]', () {
      final buffer = LandmarkSequenceBuffer(maxFrames: 2);

      buffer.add([1.5, 2.5]);
      buffer.add([3.5, 4.5]);

      final nested = buffer.toNestedTensor(featureDim: 2);
      expect(nested, isNotNull);
      expect(nested!.length, equals(1));
      expect(nested[0].length, equals(2));
      expect(nested[0][0], equals([1.5, 2.5]));
      expect(nested[0][1], equals([3.5, 4.5]));
    });

    test('Clear resets buffer to empty', () {
      final buffer = LandmarkSequenceBuffer(maxFrames: 3);
      buffer.add([1.0]);
      buffer.add([2.0]);
      buffer.add([3.0]);
      expect(buffer.isReady, isTrue);

      buffer.clear();
      expect(buffer.isReady, isFalse);
      expect(buffer.currentFrames, equals(0));
      expect(buffer.toInputTensor(featureDim: 1), isNull);
    });
  });
}
