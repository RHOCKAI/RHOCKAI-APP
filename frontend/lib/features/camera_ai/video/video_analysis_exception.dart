/// Base class for video analysis exceptions
///
/// All exceptions provide user-friendly messages suitable for display
sealed class VideoAnalysisException implements Exception {
  final String message;
  final String userMessage;

  const VideoAnalysisException(this.message, this.userMessage);

  @override
  String toString() => 'VideoAnalysisException: $message';
}

/// Video format is not supported
class UnsupportedFormatException extends VideoAnalysisException {
  UnsupportedFormatException([String? format])
      : super(
          'Unsupported video format${format != null ? ": $format" : ""}',
          'This video format is not supported. Please use MP4 or MOV files.',
        );
}

/// No pose detected in the video
class NoPoseDetectedException extends VideoAnalysisException {
  const NoPoseDetectedException()
      : super(
          'No pose detected in video',
          'Could not detect a person in the video. Please ensure:\n'
              '• You are clearly visible in the frame\n'
              '• Good lighting conditions\n'
              '• Camera is stable',
        );
}

/// Video is too short for analysis
class VideoTooShortException extends VideoAnalysisException {
  final Duration duration;
  final Duration minimumDuration;

  VideoTooShortException(this.duration, this.minimumDuration)
      : super(
          'Video too short: ${duration.inSeconds}s (minimum: ${minimumDuration.inSeconds}s)',
          'Video is too short for analysis. Please upload a video of at least ${minimumDuration.inSeconds} seconds.',
        );
}

/// Video file is corrupted or unreadable
class CorruptedFileException extends VideoAnalysisException {
  const CorruptedFileException()
      : super(
          'Video file is corrupted or unreadable',
          'This video file appears to be corrupted. Please try:\n'
              '• Re-recording the video\n'
              '• Using a different file\n'
              '• Checking the file is not damaged',
        );
}

/// Pose detection confidence is too low
class LowConfidenceException extends VideoAnalysisException {
  final double averageConfidence;
  final double minimumConfidence;

  LowConfidenceException(this.averageConfidence, this.minimumConfidence)
      : super(
          'Low confidence: ${(averageConfidence * 100).toStringAsFixed(1)}% (minimum: ${(minimumConfidence * 100).toStringAsFixed(1)}%)',
          'Could not reliably detect your pose. Please ensure:\n'
              '• Full body is visible in frame\n'
              '• Good lighting\n'
              '• Minimal background clutter\n'
              '• Camera is stable',
        );
}

/// Analysis was cancelled by user
class AnalysisCancelledException extends VideoAnalysisException {
  const AnalysisCancelledException()
      : super(
          'Analysis cancelled by user',
          'Analysis was cancelled.',
        );
}

/// Generic analysis error
class AnalysisFailedException extends VideoAnalysisException {
  AnalysisFailedException([String? details])
      : super(
          'Analysis failed${details != null ? ": $details" : ""}',
          'An error occurred during analysis. Please try again.',
        );
}
