import 'session_report.dart';

/// Progress tracking for video analysis
///
/// Used to provide real-time feedback during analysis
class AnalysisProgress {
  /// Progress value (0.0 to 1.0)
  final double progress;

  /// Current stage message for user display
  /// e.g., "Detecting poses...", "Counting repetitions..."
  final String stage;

  /// Number of frames processed so far
  final int framesProcessed;

  /// Total frames to process
  final int totalFrames;

  /// Final analysis report (only present if complete)
  final SessionReport? report;

  const AnalysisProgress({
    required this.progress,
    required this.stage,
    required this.framesProcessed,
    required this.totalFrames,
    this.report,
  });

  /// Progress as percentage (0-100)
  int get percentage => (progress * 100).round();

  /// Whether analysis is complete
  bool get isComplete => progress >= 1.0;

  /// Create initial progress
  factory AnalysisProgress.initial(int totalFrames) {
    return AnalysisProgress(
      progress: 0.0,
      stage: 'Preparing video...',
      framesProcessed: 0,
      totalFrames: totalFrames,
      report: null,
    );
  }

  /// Create progress with automatic stage detection
  factory AnalysisProgress.fromFrameCount({
    required int framesProcessed,
    required int totalFrames,
  }) {
    final progress = totalFrames > 0 ? framesProcessed / totalFrames : 0.0;
    final stage = _getStageForProgress(progress);

    return AnalysisProgress(
      progress: progress,
      stage: stage,
      framesProcessed: framesProcessed,
      totalFrames: totalFrames,
      report: null,
    );
  }

  /// Get stage message based on progress
  static String _getStageForProgress(double progress) {
    if (progress < 0.2) {
      return 'Extracting frames...';
    } else if (progress < 0.6) {
      return 'Detecting poses...';
    } else if (progress < 0.85) {
      return 'Counting repetitions...';
    } else if (progress < 0.95) {
      return 'Evaluating form...';
    } else if (progress < 1.0) {
      return 'Generating report...';
    } else {
      return 'Complete!';
    }
  }

  /// Copy with modifications
  AnalysisProgress copyWith({
    double? progress,
    String? stage,
    int? framesProcessed,
    int? totalFrames,
  }) {
    return AnalysisProgress(
      progress: progress ?? this.progress,
      stage: stage ?? this.stage,
      framesProcessed: framesProcessed ?? this.framesProcessed,
      totalFrames: totalFrames ?? this.totalFrames,
      report: report ?? report,
    );
  }

  @override
  String toString() {
    return 'AnalysisProgress($percentage%: $stage)';
  }
}
