import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_analysis_provider.dart';
import '../video/video_analysis_config.dart';
import 'video_results_screen.dart';

/// Full-screen video analysis with progress tracking
///
/// Displays:
/// - Video thumbnail preview
/// - Circular progress indicator (0-100%)
/// - Staged feedback messages
/// - Cancel button
class VideoAnalysisScreen extends ConsumerStatefulWidget {
  final File videoFile;
  final String exerciseType;
  final VideoAnalysisConfig? config;

  const VideoAnalysisScreen({
    required this.videoFile,
    required this.exerciseType,
    this.config,
    super.key,
  });

  @override
  ConsumerState<VideoAnalysisScreen> createState() =>
      _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends ConsumerState<VideoAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // Start analysis on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoAnalysisProvider.notifier).analyzeVideo(
            widget.videoFile,
            widget.exerciseType,
            config: widget.config,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(videoAnalysisProvider);

    // Navigate to results when complete
    if (analysisState.report != null && !analysisState.isAnalyzing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoResultsScreen(
              report: analysisState.report!,
            ),
          ),
        );
      });
    }

    // Show error dialog if error occurred
    if (analysisState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(analysisState.error!);
      });
    }

    final progress = analysisState.progress;
    final percentage = progress?.percentage ?? 0;
    final stage = progress?.stage ?? 'Preparing...';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Analyzing Video'),
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress circle
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                    // Percentage text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF4A90E2).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            stage,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A90E2),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF4A90E2),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Analyzing Your Workout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our AI is analyzing your form, counting reps, and providing personalized feedback.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Cancel button
              TextButton.icon(
                onPressed: _showCancelDialog,
                icon: const Icon(Icons.close, color: Color(0xFFE74C3C)),
                label: const Text(
                  'Cancel Analysis',
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Analysis?'),
        content:
            const Text('Are you sure you want to cancel the video analysis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () {
              ref.read(videoAnalysisProvider.notifier).cancel();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close analysis screen
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close analysis screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
