import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../video/video_analysis_service.dart';
import '../video/session_report.dart';
import '../video/analysis_progress.dart';
import '../video/video_analysis_config.dart';

/// State for video analysis
class VideoAnalysisState {
  final bool isAnalyzing;
  final AnalysisProgress? progress;
  final SessionReport? report;
  final String? error;
  
  const VideoAnalysisState({
    this.isAnalyzing = false,
    this.progress,
    this.report,
    this.error,
  });
  
  VideoAnalysisState copyWith({
    bool? isAnalyzing,
    AnalysisProgress? progress,
    SessionReport? report,
    String? error,
  }) {
    return VideoAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      progress: progress ?? this.progress,
      report: report ?? this.report,
      error: error ?? this.error,
    );
  }
  
  /// Reset to initial state
  VideoAnalysisState reset() {
    return const VideoAnalysisState();
  }
}

/// Provider for video analysis service
final videoAnalysisServiceProvider = Provider<VideoAnalysisService>((ref) {
  final service = VideoAnalysisService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// State notifier for video analysis
class VideoAnalysisNotifier extends StateNotifier<VideoAnalysisState> {
  final VideoAnalysisService _service;
  
  VideoAnalysisNotifier(this._service) : super(const VideoAnalysisState());
  
  /// Analyze a video file
  Future<void> analyzeVideo(
    File videoFile,
    String exerciseType, {
    VideoAnalysisConfig? config,
  }) async {
    try {
      // Reset state
      state = const VideoAnalysisState(isAnalyzing: true);
      
      // Stream progress updates
      await for (final progress in _service.analyzeVideoWithProgress(
        videoFile,
        exerciseType,
        config: config,
      )) {
        state = state.copyWith(
          isAnalyzing: !progress.isComplete,
          progress: progress,
          report: progress.report,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
    }
  }
  
  /// Cancel ongoing analysis
  void cancel() {
    _service.cancel();
    state = state.reset();
  }
  
  /// Reset state
  void reset() {
    state = state.reset();
  }
}

/// Provider for video analysis state
final videoAnalysisProvider = StateNotifierProvider<VideoAnalysisNotifier, VideoAnalysisState>((ref) {
  final service = ref.watch(videoAnalysisServiceProvider);
  return VideoAnalysisNotifier(service);
});
