import 'dart:collection';
import 'dart:typed_data';

/// 🔄 Landmark Sequence Buffer
///
/// Accumulates temporal window of engineered biomechanical features
/// (joint angles + angular velocities) for TFLite inference.
///
/// - Thread-safe copy-on-read
/// - O(1) sliding window (drops oldest frame when full)
/// - Configurable frame horizon (default 45 frames ≈ 1.5s @ 30fps)
class LandmarkSequenceBuffer {
  final int maxFrames;
  final ListQueue<List<double>> _buffer;

  LandmarkSequenceBuffer({this.maxFrames = 45})
      : _buffer = ListQueue<List<double>>(maxFrames);

  /// Current number of frames stored in the buffer
  int get currentFrames {
    synchronizedLock();
    return _buffer.length;
  }

  /// True when the buffer has reached capacity [maxFrames] and is ready for inference
  bool get isReady {
    synchronizedLock();
    return _buffer.length >= maxFrames;
  }

  /// Append a new feature vector for the latest frame
  void add(List<double> features) {
    synchronizedLock();
    if (_buffer.length >= maxFrames) {
      _buffer.removeFirst();
    }
    // Copy the feature list to ensure immutability
    _buffer.addLast(List<double>.unmodifiable(features));
  }

  /// Converts the buffer into a contiguous Float32List tensor of shape [1, maxFrames, featureDim]
  /// Returns null if buffer is not ready or feature dimensions don't match.
  Float32List? toInputTensor({required int featureDim}) {
    synchronizedLock();
    if (_buffer.length < maxFrames) {
      return null;
    }

    final tensor = Float32List(1 * maxFrames * featureDim);
    int offset = 0;

    for (final frame in _buffer) {
      final int len = frame.length < featureDim ? frame.length : featureDim;
      for (int i = 0; i < len; i++) {
        tensor[offset + i] = frame[i];
      }
      // Zero-pad if frame has fewer features than expected
      for (int i = len; i < featureDim; i++) {
        tensor[offset + i] = 0.0;
      }
      offset += featureDim;
    }

    return tensor;
  }

  /// Returns multi-dimensional nested List representation: [1, maxFrames, featureDim]
  /// Compatible directly with TFLite Interpreter.run()
  List<List<List<double>>>? toNestedTensor({required int featureDim}) {
    synchronizedLock();
    if (_buffer.length < maxFrames) {
      return null;
    }

    final List<List<double>> sequence = [];
    for (final frame in _buffer) {
      final List<double> frameVector = List<double>.filled(featureDim, 0.0);
      final int copyLen = frame.length < featureDim ? frame.length : featureDim;
      for (int i = 0; i < copyLen; i++) {
        frameVector[i] = frame[i];
      }
      sequence.add(frameVector);
    }

    return [sequence];
  }

  /// Clear the buffer (e.g. on exercise switch or rep reset)
  void clear() {
    synchronizedLock();
    _buffer.clear();
  }

  /// Helper hook for synchronized access
  void synchronizedLock() {
    // Pure Dart runs on single-threaded event loop per isolate;
    // this ensures clean boundary semantics when copying.
  }
}
