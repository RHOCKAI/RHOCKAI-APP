import 'dart:async';
import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../pose/pose_landmark_model.dart';
import '../analysis/rep_state_machine.dart';
import '../analysis/form_checker.dart';
import 'frame_source.dart';
import 'video_file_frame_source.dart';
import 'video_analysis_config.dart';
import 'session_report.dart';
import 'analysis_progress.dart';
import 'video_analysis_exception.dart';

/// Core service for analyzing workout videos
///
/// Orchestrates:
/// - Frame extraction from video files
/// - Pose detection using ML Kit
/// - Rep counting using RepStateMachine
/// - Form checking using FormChecker
/// - Progress tracking and reporting
///
/// Design principles:
/// - Sequential processing (no heavy parallelism)
/// - Memory efficient (no frame caching)
/// - Reuses existing AI engine components
/// - Proper resource disposal
class VideoAnalysisService {
  PoseDetector? _poseDetector;
  bool _isCancelled = false;

  /// Analyze a video file and return session report
  ///
  /// Throws:
  /// - [VideoAnalysisException] for various error conditions
  /// - [AnalysisCancelledException] if cancelled
  Future<SessionReport> analyzeVideo(
    File videoFile,
    String exerciseType, {
    VideoAnalysisConfig? config,
  }) async {
    SessionReport? report;

    await for (final progress in analyzeVideoWithProgress(
      videoFile,
      exerciseType,
      config: config,
    )) {
      if (progress.isComplete && progress.report != null) {
        report = progress.report;
      }
    }

    if (report == null) {
      throw AnalysisFailedException('No report generated');
    }

    return report;
  }

  /// Analyze video with progress updates
  ///
  /// Yields [AnalysisProgress] updates throughout the process
  /// Final progress includes the session report
  Stream<AnalysisProgress> analyzeVideoWithProgress(
    File videoFile,
    String exerciseType, {
    VideoAnalysisConfig? config,
  }) async* {
    _isCancelled = false;
    config ??= const VideoAnalysisConfig.performance();

    FrameSource? frameSource;

    try {
      // Validate video file
      if (!videoFile.existsSync()) {
        throw const CorruptedFileException();
      }

      // Initialize pose detector
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.single,
          model: config.model,
        ),
      );

      // Create frame source
      frameSource = VideoFileFrameSource(
        videoFile: videoFile,
        config: config,
      );

      // Initialize rep state machine
      final exerciseTypeEnum = _parseExerciseType(exerciseType);
      final repMachine = RepStateMachine(exerciseTypeEnum);

      // Track analysis data
      final List<double> accuracyScores = [];
      final Map<String, int> formIssueCount = {};
      int framesProcessed = 0;
      int framesWithPose = 0;
      int totalFrames = 0;

      // Process frames
      await for (final inputImage in frameSource.frames()) {
        if (_isCancelled) {
          throw const AnalysisCancelledException();
        }

        totalFrames++;

        // Yield progress update
        yield AnalysisProgress.fromFrameCount(
          framesProcessed: framesProcessed,
          totalFrames: totalFrames,
        );

        try {
          // Detect pose
          final poses = await _poseDetector!.processImage(inputImage);

          if (poses.isEmpty) {
            framesProcessed++;
            continue;
          }

          final pose = PoseLandmarks.fromMLKit(poses.first);

          // Check confidence
          if (!pose.hasGoodConfidence(config.minConfidence)) {
            framesProcessed++;
            continue;
          }

          framesWithPose++;

          // Process rep
          repMachine.processPose(pose);

          // Check form
          final formFeedback = FormChecker.checkForm(exerciseType, pose);
          accuracyScores.add(formFeedback.accuracy);

          // Track form issues
          for (final issue in formFeedback.issues) {
            formIssueCount[issue] = (formIssueCount[issue] ?? 0) + 1;
          }

          framesProcessed++;

          // Yield to event loop every 10 frames
          if (framesProcessed % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        } catch (e) {
          // Skip problematic frames
          framesProcessed++;
          continue;
        }
      }

      // Validate minimum frames
      if (framesWithPose < 10) {
        throw const NoPoseDetectedException();
      }

      // Calculate average confidence
      final avgConfidence = framesWithPose / totalFrames;
      if (avgConfidence < 0.3) {
        throw LowConfidenceException(avgConfidence, 0.3);
      }

      // Generate report
      final report = _generateReport(
        repMachine: repMachine,
        accuracyScores: accuracyScores,
        formIssueCount: formIssueCount,
        duration: frameSource.duration ?? Duration.zero,
        exerciseType: exerciseType,
      );

      // Yield final progress with report
      yield AnalysisProgress(
        progress: 1.0,
        stage: 'Complete!',
        framesProcessed: totalFrames,
        totalFrames: totalFrames,
        report: report,
      );
    } finally {
      // Cleanup
      frameSource?.dispose();
      await _poseDetector?.close();
      _poseDetector = null;
    }
  }

  /// Generate session report from analysis data
  SessionReport _generateReport({
    required RepStateMachine repMachine,
    required List<double> accuracyScores,
    required Map<String, int> formIssueCount,
    required Duration duration,
    required String exerciseType,
  }) {
    // Calculate metrics
    final totalReps = repMachine.repCount;
    final averageAccuracy = accuracyScores.isNotEmpty
        ? accuracyScores.reduce((a, b) => a + b) / accuracyScores.length
        : 0.0;
    final correctReps = (totalReps * (averageAccuracy / 100)).round();

    // Get top 5 form issues
    final sortedIssues = formIssueCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final keyCorrections = sortedIssues.take(5).map((e) => e.key).toList();

    return SessionReport(
      totalReps: totalReps,
      correctReps: correctReps,
      averageAccuracy: averageAccuracy,
      duration: duration,
      keyCorrections: keyCorrections,
      exerciseType: exerciseType,
      metrics: {
        'tempo_score': repMachine.lastTempoScore,
      },
    );
  }

  /// Parse exercise type string to enum
  ExerciseType _parseExerciseType(String type) {
    switch (type.toLowerCase()) {
      case 'pushup':
      case 'push-up':
      case 'push_up':
        return ExerciseType.pushup;
      case 'squat':
      case 'squats':
        return ExerciseType.squat;
      case 'plank':
      case 'planks':
        return ExerciseType.plank;
      default:
        return ExerciseType.pushup;
    }
  }

  /// Cancel ongoing analysis
  void cancel() {
    _isCancelled = true;
  }

  /// Dispose resources
  void dispose() {
    _poseDetector?.close();
    _poseDetector = null;
  }
}
