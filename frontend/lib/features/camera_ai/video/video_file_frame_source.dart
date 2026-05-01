import 'dart:async';
import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'frame_source.dart';
import 'video_analysis_config.dart';
import 'video_analysis_exception.dart';

/// Frame source that extracts frames from video files
///
/// Uses ffmpeg_kit_flutter for high-quality native frame extraction.
class VideoFileFrameSource implements FrameSource {
  final File videoFile;
  final VideoAnalysisConfig config;

  Directory? _tempDir;
  List<File>? _extractedFrames;
  bool _disposed = false;

  VideoFileFrameSource({
    required this.videoFile,
    VideoAnalysisConfig? config,
  }) : config = config ?? const VideoAnalysisConfig.performance();

  @override
  int? get totalFrames => _extractedFrames?.length;

  @override
  Duration? duration;

  @override
  Stream<InputImage> frames() async* {
    if (_disposed) {
      throw StateError('FrameSource has been disposed');
    }

    try {
      if (_extractedFrames == null) {
        await _extractFrames();
      }

      if (_extractedFrames == null || _extractedFrames!.isEmpty) {
        throw const NoPoseDetectedException();
      }

      for (int i = 0; i < _extractedFrames!.length; i++) {
        if (_disposed) {
          break;
        }

        final frameFile = _extractedFrames![i];

        try {
          final inputImage = InputImage.fromFilePath(frameFile.path);
          yield inputImage;

          if (i % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      if (e is VideoAnalysisException) {
        rethrow;
      }
      throw AnalysisFailedException(e.toString());
    }
  }

  Future<void> _extractFrames() async {
    final tempDir = await getTemporaryDirectory();
    final uniqueDirName =
        'video_frames_${DateTime.now().millisecondsSinceEpoch}';
    _tempDir = Directory(path.join(tempDir.path, uniqueDirName));
    await _tempDir!.create(recursive: true);

    // Attempt extract
    try {
      final outputPath = path.join(_tempDir!.path, 'frame_%04d.jpg');

      // FFmpeg command to extract frames at the specified FPS and scale
      // -i: input file
      // -vf: video filter (fps and scale)
      // outputPath: pattern for output files
      final ffmpegCommand =
          '-i "${videoFile.path}" -vf "fps=${config.fps},scale=${config.maxWidth}:-1" "$outputPath"';

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (returnCode == null || !ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        throw AnalysisFailedException(
            'FFmpeg failed with code $returnCode. Logs: $logs');
      }

      final frames = _tempDir!
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      if (frames.isEmpty) {
        throw const NoPoseDetectedException();
      }

      _extractedFrames = frames;
      duration =
          Duration(milliseconds: (frames.length / config.fps * 1000).round());
    } catch (e) {
      if (e is VideoAnalysisException) {
        rethrow;
      }
      throw AnalysisFailedException('Frame extraction failed: $e');
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_tempDir != null && _tempDir!.existsSync()) {
      try {
        _tempDir!.deleteSync(recursive: true);
      } catch (e) {
        // Silently fail during disposal if directory deletion fails
      }
    }
  }
}
