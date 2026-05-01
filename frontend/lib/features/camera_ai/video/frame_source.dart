import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Abstract interface for frame providers
/// 
/// This abstraction enables different frame sources (video files, live camera, etc.)
/// to be used interchangeably with the pose analysis engine.
/// 
/// Design principle: Separation of frame acquisition from pose processing
abstract class FrameSource {
  /// Stream of frames as InputImage for ML Kit pose detection
  /// 
  /// Implementations should:
  /// - Yield frames at appropriate FPS (e.g., 5 FPS for video files)
  /// - Downscale frames to reduce computation
  /// - Handle errors gracefully
  /// - Dispose resources when stream is cancelled
  Stream<InputImage> frames();
  
  /// Total number of frames (if known), null otherwise
  /// Used for progress calculation
  int? get totalFrames;
  
  /// Duration of the source (if known), null otherwise
  Duration? get duration;
  
  /// Dispose resources and cleanup
  /// Must be called when done using the frame source
  void dispose();
}
