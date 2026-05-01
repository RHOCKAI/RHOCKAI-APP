import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Configuration for video analysis performance tuning
/// 
/// Default values prioritize performance for mid-range devices
/// while maintaining acceptable accuracy for rep counting.
class VideoAnalysisConfig {
  /// Frames per second to sample from video
  /// Default: 5 FPS (6x faster than 30 FPS)
  /// Lower = faster processing, higher = more accurate
  final int fps;
  
  /// Maximum frame width in pixels
  /// Default: 640px (reduces computation by ~50%)
  /// Frames are downscaled proportionally
  final int maxWidth;
  
  /// Pose detection model to use
  /// Default: base (3x faster than accurate)
  /// base = faster, accurate = more precise
  final PoseDetectionModel model;
  
  /// Minimum confidence threshold for pose landmarks
  /// Default: 0.5 (50%)
  /// Frames with lower confidence are skipped
  final double minConfidence;
  
  const VideoAnalysisConfig({
    this.fps = 5,
    this.maxWidth = 640,
    this.model = PoseDetectionModel.base,
    this.minConfidence = 0.5,
  });
  
  /// Performance-optimized configuration (default)
  /// Best for mid-range devices
  const VideoAnalysisConfig.performance()
      : fps = 5,
        maxWidth = 640,
        model = PoseDetectionModel.base,
        minConfidence = 0.5;
  
  /// Balanced configuration
  /// Good balance between speed and accuracy
  const VideoAnalysisConfig.balanced()
      : fps = 8,
        maxWidth = 720,
        model = PoseDetectionModel.base,
        minConfidence = 0.6;
  
  /// High-quality configuration (premium mode)
  /// Best accuracy, slower processing
  /// Recommended for high-end devices only
  const VideoAnalysisConfig.quality()
      : fps = 15,
        maxWidth = 1280,
        model = PoseDetectionModel.accurate,
        minConfidence = 0.7;
  
  /// Copy with modifications
  VideoAnalysisConfig copyWith({
    int? fps,
    int? maxWidth,
    PoseDetectionModel? model,
    double? minConfidence,
  }) {
    return VideoAnalysisConfig(
      fps: fps ?? this.fps,
      maxWidth: maxWidth ?? this.maxWidth,
      model: model ?? this.model,
      minConfidence: minConfidence ?? this.minConfidence,
    );
  }
}
