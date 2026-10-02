import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rhockai/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' hide PoseLandmark;

import 'pose/pose_landmark_model.dart';
import 'analysis/rep_state_machine.dart';
import 'analysis/form_checker.dart';
import 'analysis/environment_validator.dart';
import 'analysis/landmark_smoother.dart';
import 'analysis/pose_quality_checker.dart';
import 'analysis/pose_config.dart';
import 'session/session_model.dart';
import 'session/session_provider.dart';
import 'package:rhockai/core/constants/exercises.dart';
import 'package:rhockai/shared/widgets/pulse_animation.dart';
import 'package:rhockai/features/gamification/providers/gamification_provider.dart';
import 'package:rhockai/core/providers/settings_provider.dart';
import 'package:rhockai/features/analytics/providers/analytics_provider.dart';
import 'package:rhockai/features/workout/workout_summary_screen.dart';
import 'services/voice_feedback_service.dart';
import 'services/voice_command_service.dart';
import 'package:rhockai/core/services/health_service.dart';
import 'widgets/ai_coach_mic_button.dart';

/// 📸 Enhanced Camera AI Screen - Futuristic Workout Overlay
class CameraAIScreen extends ConsumerStatefulWidget {
  final String exerciseType;
  final bool isDemo;

  const CameraAIScreen({
    required this.exerciseType,
    this.isDemo = false,
    super.key,
  });

  @override
  ConsumerState<CameraAIScreen> createState() => _CameraAIScreenState();
}

class _CameraAIScreenState extends ConsumerState<CameraAIScreen>
    with TickerProviderStateMixin {
  // Logic Controllers
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  CameraLensDirection _currentCameraFacing = CameraLensDirection.front;
  PoseDetector? _poseDetector;
  RepStateMachine? _repMachine;

  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _isSwitchingCamera = false;
  bool _isWorkoutActive = false;
  bool _isSetupPhase = true; // New phase for pre-flight check

  // ML Pipeline Improvements
  late LandmarkSmoother _smoother;
  PoseQualityChecker? _qualityChecker;
  DateTime _lastFrameTime = DateTime.now();

  // Data
  int _repCount = 0; // Total session reps
  int _repsInSet = 0; // Reps in current set
  int _currentSet = 1;
  int _targetReps = 10;
  int _targetSets = 3;

  // Rest Timer
  bool _isResting = false;
  Timer? _restTimer;
  int _restSecondsRemaining = 30;
  static const int _defaultRestDuration = 30;

  // Warmup Timer
  bool _isWarmingUp = true;
  int _warmupSecondsRemaining = 10;
  Timer? _warmupTimer;

  // Calibration Progress for Holographic Lock-On
  double _calibrationProgress = 0.0;

  double _accuracy = 100.0;
  String _feedbackMessage = 'Get ready...';
  Color _feedbackColor = const Color(0xFF00D9FF); // Neon Blue
  PoseLandmarks? _currentPose;
  String _environmentMessage = 'Analyzing environment...';
  bool _isEnvironmentValid = false;
  
  // Wearables
  double? _currentHeartRate;
  Timer? _heartRateTimer;
  
  // Error Handling
  String? _errorMessage;
  int _mlKitErrorCount = 0;
  static const int _maxMlKitErrors = 5;
  
  Size? _imageSize;

  // Animation Controllers
  late AnimationController _counterController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
    _initializeRepMachine();
    _initializeExerciseTarget();

    // Start heart rate polling
    _startHeartRatePolling();
    
    // Counter animation
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Start session in background
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(sessionProvider.notifier).startSession(widget.exerciseType);

      // Initialize Voice Feedback
      final settings = ref.read(settingsProvider);
      final voiceService = VoiceFeedbackService();
      await voiceService.initialize();
      voiceService.setEnabled(settings.voiceEnabled);
      await voiceService.setVoice(personality: settings.voicePersonality);

      final analytics = ref.read(analyticsServiceProvider);
      await analytics.trackFeature(
        'workout',
        'started',
        extraData: {'exercise': widget.exerciseType},
      );

      // Initialize Voice Commands
      if (settings.voiceEnabled) {
        final voiceCommandService = VoiceCommandService();
        await voiceCommandService.initialize();
        await voiceCommandService.startListening(_handleVoiceCommand);
      }

      setState(() {
        // Start in Setup phase
        _isSetupPhase = true;
        _isWarmingUp = false;
        _isWorkoutActive = false;
      });
    });
  }

  void _handleVoiceCommand(WorkoutCommand command) {
    if (!mounted) {
      return;
    }
    
    debugPrint('Voice command received in UI: $command');
    
    switch (command) {
      case WorkoutCommand.start:
      case WorkoutCommand.resume:
        if (_isWarmingUp) {
          _endWarmup();
        } else if (!_isWorkoutActive) {
          setState(() {
            _isWorkoutActive = true;
            _feedbackMessage = AppLocalizations.of(context)?.resuming ?? 'Resuming...';
          });
        }
        break;
      case WorkoutCommand.pause:
        if (_isWorkoutActive) {
          setState(() {
            _isWorkoutActive = false;
            _feedbackMessage = AppLocalizations.of(context)?.paused ?? 'Paused';
          });
        }
        break;
      case WorkoutCommand.stop:
        if (_isWorkoutActive || _isWarmingUp) {
          _completeWorkout();
        }
        break;
      default:
        break;
    }
  }

  void _startWarmup() {
    setState(() {
      _isWarmingUp = true;
      _isSetupPhase = false;
      _isWorkoutActive = false;
      _feedbackMessage = AppLocalizations.of(context)?.getReady ?? 'Get ready...';
      _feedbackColor = const Color(0xFFFFD700); // Gold
    });

    _warmupTimer?.cancel();
    _warmupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_warmupSecondsRemaining > 0) {
        setState(() {
          _warmupSecondsRemaining--;
          if (_warmupSecondsRemaining <= 3) {
            _feedbackColor = const Color(0xFFFF6B35); // Orange warning
            _counterController.forward(from: 0);
          }
        });
      } else {
        _endWarmup();
      }
    });

    // Start countdown voice
    VoiceFeedbackService().countdown();
    
    // Start wearable sync
    _startHeartRatePolling();
  }

  void _endWarmup() {
    _warmupTimer?.cancel();
    if (!mounted) {
      return;
    }

    setState(() {
      _feedbackMessage = AppLocalizations.of(context)?.go ?? 'GO!';
      _feedbackColor = const Color(0xFF00FF88);
    });

    // Start video recording
    _startRecording();

    // Clear "GO!" after a second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isWorkoutActive) {
        setState(() {
          _feedbackMessage = AppLocalizations.of(context)?.keepGoing ?? 'Keep going!';
        });
      }
    });
  }

  void _skipWarmup() {
    _endWarmup();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    _counterController.dispose();
    _restTimer?.cancel();
    _warmupTimer?.cancel();
    _heartRateTimer?.cancel();
    _smoother.dispose();
    _qualityChecker?.dispose();
    VoiceCommandService().stopListening();
    super.dispose();
  }

  // --- Initialization & Logic ---

  Future<void> _initializeCamera() async {
    final l10n = AppLocalizations.of(context);
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        _handleError(l10n?.noCamerasFound ?? 'No cameras found on this device.');
        return;
      }
      await _startCamera(_currentCameraFacing);
    } catch (e) {
      _handleError(l10n?.cameraPermissionError ?? 'Failed to access cameras. Please check permissions.');
      debugPrint('Camera initialization error: $e');
    }
  }

  void _handleError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isWorkoutActive = false;
    });
  }

  void _retryInitialization() {
    setState(() {
      _errorMessage = null;
      _mlKitErrorCount = 0;
    });
    _initializeCamera();
    _initializePoseDetector();
  }

  Future<void> _startCamera(CameraLensDirection direction) async {
    try {
      final camera = _availableCameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => _availableCameras.first,
      );

      final newController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      // Dispose old controller
      await _cameraController?.dispose();

      setState(() {
        _cameraController = newController;
        _currentCameraFacing = direction;
        _isCameraInitialized = true;
        _isSwitchingCamera = false;
      });

      _startImageStream();
    } catch (e) {
      debugPrint('Camera start error: $e');
      if (mounted) {
        setState(() => _isSwitchingCamera = false);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || _availableCameras.length < 2) {
      return;
    }
    setState(() {
      _isCameraInitialized = false;
      _isSwitchingCamera = true;
    });
    final newDirection = _currentCameraFacing == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _startCamera(newDirection);
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      await _cameraController!.startVideoRecording();
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  Future<String?> _stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return null;
    }
    try {
      final file = await _cameraController!.stopVideoRecording();
      return file.path;
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      return null;
    }
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }

  void _initializeRepMachine() {
    _smoother = LandmarkSmoother(alpha: widget.exerciseType.toLowerCase() == 'plank' ? 0.4 : 0.6);
    final typeMap = {
      'pushup': ExerciseType.pushup,
      'push-up': ExerciseType.pushup,
      'squat': ExerciseType.squat,
      'plank': ExerciseType.plank,
      'glute_bridge': ExerciseType.gluteBridge,
      'inchworm': ExerciseType.inchworm,
      'high_knees': ExerciseType.highKnees,
      'lunge': ExerciseType.lunge,
      'tricep_dip': ExerciseType.tricepDip,
      'mountain_climber': ExerciseType.mountainClimber,
      'side_plank': ExerciseType.sidePlank,
      'reverse_lunge': ExerciseType.reverseLunge,
      'pike_pushup': ExerciseType.pikePushup,
      'sumo_squat': ExerciseType.sumoSquat,
      'pistol_squat': ExerciseType.pistolSquat,
      'diamond_pushup': ExerciseType.diamondPushup,
      'archer_pushup': ExerciseType.archerPushup,
      'jump_squat': ExerciseType.jumpSquat,
      'burpee': ExerciseType.burpee,
      'single_leg_deadlift': ExerciseType.singleLegDeadlift,
      'spiderman_pushup': ExerciseType.spidermanPushup,
    };

    final type = typeMap[widget.exerciseType.toLowerCase()] ?? ExerciseType.pushup;
    _repMachine = RepStateMachine(type);
  }

  void _initializeExerciseTarget() {
    final exerciseData = Exercises.getById(widget.exerciseType);
    if (exerciseData != null) {
      _targetReps = exerciseData.defaultReps;
      _targetSets = exerciseData.defaultSets;
    }
  }

  void _startRest() {
    setState(() {
      _isResting = true;
      _isWorkoutActive = false;
      _restSecondsRemaining = _defaultRestDuration;
      _feedbackMessage = 'Rest Time';
      _feedbackColor = const Color(0xFF00D9FF);
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_restSecondsRemaining > 0) {
          _restSecondsRemaining--;
        } else {
          _endRest();
        }
      });
    });
  }

  void _endRest() {
    _restTimer?.cancel();
    if (!mounted) {
      return;
    }

    setState(() {
      _isResting = false;
      _isWorkoutActive = true;
      _repsInSet = 0; // Reset for next set
      _currentSet++;

      // Keep feedback message transient or reset
      _feedbackMessage = AppLocalizations.of(context)?.keepGoing ?? 'Keep going!';
    });
  }

  void _skipRest() {
    _endRest();
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting || _errorMessage != null) {
        return;
      }

      if (!_isWorkoutActive && !_isSetupPhase) {
        return;
      }

      _isDetecting = true;

      try {
        await _processImage(image);
        _mlKitErrorCount = 0; // Reset on success
      } catch (e) {
        debugPrint('Image processing error: $e');
        _mlKitErrorCount++;
        if (_mlKitErrorCount >= _maxMlKitErrors) {
          _handleError('AI engine failure. Please restart the workout.');
        }
      } finally {
        _isDetecting = false;
      }
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_poseDetector == null || _repMachine == null) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < (1000 / PoseConfig.maxProcessFps)) {
      return; 
    }
    _lastFrameTime = now;

    // Track image size for painter scaling
    if (_imageSize == null) {
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
      _qualityChecker = PoseQualityChecker(imageHeight: image.height.toDouble());
    }

    InputImage? inputImage;
    try {
       inputImage = _convertCameraImage(image);
    } catch (e) {
       debugPrint('Critical: Image conversion failed: $e');
       return;
    }

    if (inputImage == null) {
      return;
    }

    final poses = await _poseDetector!.processImage(inputImage);

    if (!mounted) {
      return;
    }

    if (poses.isEmpty) {
      _smoother.reset();
      if (mounted) {
        setState(() {
          _feedbackMessage = AppLocalizations.of(context)?.standInFrame ?? 'Stand in frame';
          _feedbackColor = const Color(0xFFFF6B35); // Neon Orange
          _currentPose = null;
        });
      }
      return;
    }

    final pose = poses.first;

    // 1. Quality Check
    if (_qualityChecker != null) {
      final quality = _qualityChecker!.check(pose);
      if (quality.quality != PoseQuality.good) {
        if (mounted) {
          setState(() {
            _feedbackMessage = quality.message ?? 'Position yourself correctly';
            _feedbackColor = const Color(0xFFFF6B35);
            _currentPose = null;
          });
        }
        return;
      }
    }

    // 2. EMA Smoothing to eliminate jitter
    final smoothedLandmarksMap = _smoother.smooth(pose.landmarks);
    final smoothedPose = Pose(landmarks: smoothedLandmarksMap);

    final poseLandmarks = PoseLandmarks.fromMLKit(smoothedPose);

    // Ensure our new PoseConfig threshold is respected natively
    if (!poseLandmarks
        .hasGoodConfidence(PoseConfig.minPoseConfidence)) {
      if (mounted) {
        setState(() {
          _feedbackMessage = AppLocalizations.of(context)?.comeCloser ?? 'Come closer';
          _feedbackColor = const Color(0xFFFF6B35);
          _currentPose = poseLandmarks;
        });
      }
      return;
    }

    final newRepCompleted = _repMachine!.processPose(poseLandmarks);
    final formFeedback =
        FormChecker.checkForm(widget.exerciseType, poseLandmarks);

    if (newRepCompleted) {
      await HapticFeedback.heavyImpact(); // Add haptic feedback for each rep
      await _counterController.forward(from: 0); // Trigger animation
      _repsInSet++;

      final repData = RepData(
        repNumber: _repMachine!.repCount,
        accuracy: formFeedback.accuracy,
        formIssues: formFeedback.issues,
        tempoScore: _repMachine!.lastTempoScore,
        timestamp: DateTime.now(),
      );
      ref.read(sessionProvider.notifier).addRep(repData);

      // Check for set completion
      if (_repsInSet >= _targetReps && _currentSet < _targetSets) {
        // Trigger rest after short delay to show the rep count update
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _startRest();
          }
        });
      } else if (_repsInSet >= _targetReps && _currentSet >= _targetSets) {
        // Workout Complete logic handled by user pressing stop or we auto-finish?
        if (mounted) {
          _feedbackMessage = AppLocalizations.of(context)?.workoutComplete ?? 'Workout complete!';
          _feedbackColor = const Color(0xFF00FF88);
          unawaited(VoiceFeedbackService().announceWorkoutComplete(_repCount, _accuracy));
        }
      }

      // Provide voice feedback for the rep
      unawaited(VoiceFeedbackService().announceRepCount(_repCount, _targetReps));
      unawaited(VoiceFeedbackService().provideFormFeedback(
        _accuracy, 
        formFeedback.issues,
        perfectionTip: formFeedback.perfectionTip,
      ));
    }

    final envStatus = EnvironmentValidator.validate(image, poseLandmarks);

    if (mounted) {
      setState(() {
        _currentPose = poseLandmarks;
        _repCount = _repMachine!.repCount;
        _accuracy = formFeedback.accuracy;
        _environmentMessage = envStatus.message;
        _isEnvironmentValid = envStatus.isValid;

        if (_isSetupPhase) {
          _feedbackMessage = envStatus.message;
          if (envStatus.isValid) {
            _feedbackColor = const Color(0xFF00FF88); // Neon green
            _calibrationProgress = (_calibrationProgress + 0.035).clamp(0.0, 1.0);
            
            // If perfectly locked, transition immediately!
            if (_calibrationProgress >= 1.0 && !_isWarmingUp && !_isWorkoutActive) {
              _isSetupPhase = false;
              HapticFeedback.heavyImpact();
              _startWarmup();
            }
          } else {
            _feedbackColor = const Color(0xFFFF6B35); // Warning Orange
            _calibrationProgress = (_calibrationProgress - 0.07).clamp(0.0, 1.0);
          }
        } else {
          _feedbackMessage = _repMachine!.getStatusMessage();
          _feedbackColor = const Color(0xFF00D9FF);
        }
      });
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    if (_cameraController == null) {
      return null;
    }

    final camera = _cameraController!.description;
    final rotation = _getImageRotation(camera);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null || image.planes.isEmpty) {
      return null;
    }

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  InputImageRotation _getImageRotation(CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    if (camera.lensDirection == CameraLensDirection.front) {
      if (Platform.isIOS) {
        return InputImageRotation.rotation270deg;
      } else {
        switch (sensorOrientation) {
          case 90:
            return InputImageRotation.rotation90deg;
          case 180:
            return InputImageRotation.rotation180deg;
          case 270:
            return InputImageRotation.rotation270deg;
          default:
            return InputImageRotation.rotation0deg;
        }
      }
    } else {
      if (Platform.isIOS) {
        return InputImageRotation.rotation90deg;
      } else {
        switch (sensorOrientation) {
          case 90:
            return InputImageRotation.rotation90deg;
          case 180:
            return InputImageRotation.rotation180deg;
          case 270:
            return InputImageRotation.rotation270deg;
          default:
            return InputImageRotation.rotation0deg;
        }
      }
    }
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF6B35), size: 64),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _retryInitialization,
                icon: const Icon(Icons.refresh),
                label: const Text('RETRY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Construction ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),

          // Environment Indicator
          _buildEnvironmentStatus(),

          // Error Overlay
          if (_errorMessage != null) _buildErrorOverlay(),

          // Pose detection overlay
          _buildPoseOverlay(),

          // Top bar
          _buildTopBar(),

          // Bottom controls
          _buildBottomControls(),

          // Rep counter (center)
          _buildRepCounter(),

          // Voice Interactive Coach Mic Button
          Positioned(
            right: 24,
            bottom: 150,
            child: AICoachMicButton(
              plannedExerciseId: 1,
              onCommandProcessed: (response) {
                if (!mounted) {
                  return;
                }
                
                setState(() {
                  _feedbackMessage = response['message'];
                  _feedbackColor = const Color(0xFFFF9900);
                  
                  if (response['action'] == 'update_reps') {
                    _targetReps = response['data']['new_reps'];
                  } else if (response['action'] == 'swap_exercise') {
                    _feedbackMessage = 'Swapping to ${response['data']['new_exercise_name']}...';
                    _feedbackColor = const Color(0xFF00D9FF);
                  }
                });
              },
            ),
          ),

          // Feedback message
          _buildFeedbackMessage(),

          // Side stats
          _buildSideStats(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: const Color(0xFF1A1A2E), // Dark placeholder
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Handle scaling safely
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
    if (scale < 1) {
      scale = 1 / scale;
    }

    return Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(_cameraController!)),
    );
  }

  Widget _buildPoseOverlay() {
    if (_imageSize == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size.infinite,
      painter: PoseOverlayPainter(
        pose: _currentPose,
        accuracy: _accuracy,
        imageSize: _imageSize!,
        isFrontCamera: _currentCameraFacing == CameraLensDirection.front,
        exerciseType: widget.exerciseType,
        isSetupPhase: _isSetupPhase,
        isWorkoutActive: _isWorkoutActive,
        calibrationProgress: _calibrationProgress,
      ),
    );
  }

  void _startHeartRatePolling() {
    _heartRateTimer?.cancel();
    _heartRateTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || !_isWorkoutActive) {
        return;
      }
      
      final heartRate = await HealthService().getLatestHeartRate();
      if (heartRate != null && mounted) {
        setState(() {
          _currentHeartRate = heartRate;
        });
      }
    });
  }

  Widget _buildHeartRateDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const PulseAnimation(
            begin: 1.0,
            end: 1.2,
            active: true,
            child: Icon(Icons.favorite, color: Colors.redAccent, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            '${_currentHeartRate?.toInt() ?? "--"}',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'BPM',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Back or Skip button
            if (widget.isDemo)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            const SizedBox(width: 16),
            // Exercise name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.exerciseType.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00D9FF),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Spacer(),
            // Camera flip button
            if (_availableCameras.length >= 2)
              GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: _isSwitchingCamera
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            const SizedBox(width: 8),
            // Heart Rate
            if (_currentHeartRate != null)
              _buildHeartRateDisplay(),
            const SizedBox(width: 8),
            // Timer / Set counter
            _buildTimerButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerButton() {
    // Ideally this comes from a Timer provider or Session provider
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.layers, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'SET $_currentSet/$_targetSets',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentStatus() {
    if (!_isSetupPhase) {
      return Positioned(
        top: 100,
        left: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isEnvironmentValid
                  ? const Color(0xFF00FF88)
                  : const Color(0xFFFF6B35),
              width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isEnvironmentValid
                  ? Icons.check_circle
                  : Icons.warning_amber_rounded,
              color: _isEnvironmentValid
                  ? const Color(0xFF00FF88)
                  : const Color(0xFFFF6B35),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _environmentMessage,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: _isEnvironmentValid
                    ? const Color(0xFF00FF88)
                    : const Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          ),
        ),
      );
    }

    // Gorgeous Translucent Futuristic CyberHUD Telemetry Card during Setup!
    return Positioned(
      top: 110,
      left: 20,
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isEnvironmentValid
                ? const Color(0xFF00FF88).withValues(alpha: 0.5)
                : const Color(0xFFFF6B35).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isEnvironmentValid ? const Color(0xFF00FF88) : const Color(0xFFFF6B35)).withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RHOCK_AI // CAMERA HUD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Rajdhani',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isEnvironmentValid ? const Color(0xFF00FF88) : const Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 12, thickness: 1),
            _buildTelemetryLine('SYS.LUM', _isEnvironmentValid ? '92% [GOOD]' : '45% [LOW]', _isEnvironmentValid ? const Color(0xFF00FF88) : const Color(0xFFFF6B35)),
            const SizedBox(height: 6),
            _buildTelemetryLine('SYS.DIST', _isEnvironmentValid ? '2.4M [STABLE]' : 'ADJUST POSITION', _isEnvironmentValid ? Colors.white : const Color(0xFFFF6B35)),
            const SizedBox(height: 6),
            _buildTelemetryLine(
              'SYS.POSE', 
              _currentPose != null ? 'LOCKED' : 'SCANNING', 
              _currentPose != null ? const Color(0xFF00FF88) : Colors.white24
            ),
            const SizedBox(height: 12),
            const Text(
              'HOLOGRAM ALIGNMENT LOCK',
              style: TextStyle(
                color: Colors.white38,
                fontFamily: 'Outfit',
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _calibrationProgress,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isEnvironmentValid ? const Color(0xFF00FF88) : const Color(0xFFFF6B35),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOCK-IN PROCESS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontFamily: 'Rajdhani',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(_calibrationProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: _isEnvironmentValid ? const Color(0xFF00FF88) : const Color(0xFFFF6B35),
                    fontFamily: 'Rajdhani',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryLine(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontFamily: 'Rajdhani',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: 'Rajdhani',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRepCounter() {
    return Center(
      child: PulseAnimation(
        begin: 1.0,
        end: 1.05,
        active: _isWorkoutActive,
        child: AnimatedBuilder(
          animation: _counterController,
          builder: (context, child) {
            final scale = 1.0 + (_counterController.value * 0.3);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _feedbackColor.withValues(alpha: 0.3),
                      _feedbackColor.withValues(alpha: 0.0),
                    ],
                  ),
                  border: Border.all(
                    color: _feedbackColor.withValues(alpha: 0.5),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isWarmingUp
                            ? '$_warmupSecondsRemaining'
                            : (_isResting
                                ? '${_restSecondsRemaining}s'
                                : '$_repsInSet'),
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: (_isResting || _isWarmingUp) ? 60 : 80,
                          fontWeight: FontWeight.w700,
                          color: _isWarmingUp
                              ? const Color(0xFFFFD700)
                              : (_isResting ? Colors.white : _feedbackColor),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isWarmingUp
                            ? 'WARMUP'
                            : (_isResting
                                ? 'REST'
                                : '${(AppLocalizations.of(context)?.repsLabel ?? 'Reps').toUpperCase()} / $_targetReps'),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeedbackMessage() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: (_isWorkoutActive || _isSetupPhase) ? 1.0 : 0.0, 
          duration: const Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _feedbackColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: _feedbackColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Text(
                _feedbackMessage,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _feedbackColor,
                  shadows: [
                    Shadow(
                      color: _feedbackColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSideStats() {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).size.height * 0.35,
      child: Column(
        children: [
          _buildStatBadge(
            AppLocalizations.of(context)?.accuracy ?? 'Accuracy',
            '${_accuracy.toInt()}%',
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 16),
          _buildStatBadge(
            AppLocalizations.of(context)?.tempo ?? 'Tempo',
            '${_repMachine?.lastTempoScore.toInt() ?? 0}',
            Icons.speed,
          ),
          const SizedBox(height: 16),
          _buildStatBadge(
            AppLocalizations.of(context)?.calories ?? 'Calories',
            '${(_repCount * (Exercises.getById(widget.exerciseType)?.caloriesPerRep ?? 0.5)).toInt()}',
            Icons.local_fire_department,
          ),
          const SizedBox(height: 16),
          _buildStatBadge(
            'PB (Ghost)',
            '${ref.watch(gamificationProvider).valueOrNull?.longestStreak ?? 0}',
            Icons.auto_awesome,
            color: const Color(0xFFB0B0B0), // Ghostly grey
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, {Color? color}) {
    final themeColor = color ?? const Color(0xFF00D9FF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
      child: Column(
        children: [
            Icon(icon, color: themeColor, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rajdhani',
              ),
            ),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.9),
                Colors.black.withValues(alpha: 0.0)
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                _isSetupPhase
                    ? Icons.play_arrow
                    : (_isResting
                        ? Icons.skip_next
                        : (_isWorkoutActive ? Icons.pause : Icons.play_arrow)),
                _isSetupPhase
                    ? 'Start'
                    : (_isResting
                        ? 'Skip Rest'
                        : (_isWorkoutActive
                            ? AppLocalizations.of(context)?.pause ?? 'Pause'
                            : AppLocalizations.of(context)?.resume ?? 'Resume')),
                () async {
                  if (_isSetupPhase) {
                    if (_isEnvironmentValid) {
                      await HapticFeedback.heavyImpact();
                      _startWarmup();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_environmentMessage)),
                      );
                    }
                    return;
                  }
                  if (_isResting) {
                    await HapticFeedback.heavyImpact();
                    _skipRest();
                    return;
                  }

                  final analytics = ref.read(analyticsServiceProvider);
                  await analytics.trackFeature(
                    'workout',
                    _isWorkoutActive ? 'paused' : 'resumed',
                    extraData: {'exercise': widget.exerciseType},
                  );
                  await HapticFeedback.heavyImpact();
                  setState(() {
                    _isWorkoutActive = !_isWorkoutActive;
                  });
                },
              ),
              if (_isWarmingUp)
                _buildControlButton(
                  Icons.skip_next,
                  'Skip',
                  _skipWarmup,
                ),
              if (!_isWarmingUp)
                _buildControlButton(
                  Icons.stop,
                  AppLocalizations.of(context)?.finish ?? 'Finish',
                  _completeWorkout,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Future<void> _completeWorkout() async {
    final analytics = ref.read(analyticsServiceProvider);
    await analytics.trackFeature(
      'workout',
      'completed',
      extraData: {
        'exercise': widget.exerciseType,
        'reps': _repCount,
        'accuracy': _accuracy,
      },
    );

    final videoPath = await _stopRecording();
    final session = ref.read(sessionProvider);
    if (session != null) {
      session.videoUrl = videoPath;
    }

    await ref.read(sessionProvider.notifier).completeSession();
    if (!mounted) {
      return;
    }

    // Navigate to summary instead of just popping
    if (session != null) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutSummaryScreen(session: session, isDemo: widget.isDemo),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}

/// 🎨 Pose Overlay Painter - Breathtaking Sci-Fi Holographic HUD
class PoseOverlayPainter extends CustomPainter {
  final PoseLandmarks? pose;
  final double accuracy;
  final Size imageSize;
  final bool isFrontCamera;
  final String exerciseType;
  final bool isSetupPhase;
  final bool isWorkoutActive;
  final double calibrationProgress;

  PoseOverlayPainter({
    required this.pose,
    required this.accuracy,
    required this.imageSize,
    required this.isFrontCamera,
    required this.exerciseType,
    required this.isSetupPhase,
    required this.isWorkoutActive,
    required this.calibrationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If no body detected in setup mode, draw a beautiful pulsing holographic wireframe outline
    if (pose == null) {
      if (isSetupPhase) {
        _drawHolographicSilhouette(canvas, size);
      }
      return;
    }

    // Modern color palette for sci-fi feedback
    final Color hudColor = accuracy >= 95 
        ? const Color(0xFF00FF88) // Hyper Neon Green (Perfect Form)
        : accuracy >= 80 
            ? const Color(0xFF00D9FF) // Laser Cyan (Good Form)
            : const Color(0xFFFF6B35); // Warning Cyber Orange

    Offset scale(PoseLandmark p) {
      if (imageSize.width == 0 || imageSize.height == 0) {
        return Offset.zero;
      }
      // Scaling using canvas vs camera coordinate maps
      double x = p.x * size.width / imageSize.width;
      double y = p.y * size.height / imageSize.height;
      
      if (isFrontCamera) {
        x = size.width - x;
      }
      
      return Offset(x, y);
    }

    // High fidelity laser/neon line painter
    void drawNeonLine(PoseLandmark p1, PoseLandmark p2, Color baseColor) {
      if (p1.likelihood < 0.5 || p2.likelihood < 0.5) {
        return;
      }
      
      final o1 = scale(p1);
      final o2 = scale(p2);
      
      // 1. Semi-transparent laser glow
      final glowPaint = Paint()
        ..shader = ui.Gradient.linear(
          o1, o2, 
          [baseColor.withValues(alpha: 0.05), baseColor.withValues(alpha: 0.35), baseColor.withValues(alpha: 0.05)]
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(o1, o2, glowPaint);
      
      // 2. Focused Neon Filament
      final corePaint = Paint()
        ..shader = ui.Gradient.linear(
          o1, o2, 
          [baseColor.withValues(alpha: 0.4), baseColor, baseColor.withValues(alpha: 0.4)]
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(o1, o2, corePaint);
      
      // 3. Ultra-bright white laser core
      final laserPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(o1, o2, laserPaint);
    }

    // Cybernetic joint rendering
    void drawCyberJoint(PoseLandmark p, Color baseColor) {
      if (p.likelihood < 0.5) {
        return;
      }
      final center = scale(p);
      
      // Pulsing outer halo
      final pulse = 1.0 + 0.15 * math.sin(DateTime.now().millisecondsSinceEpoch / 250.0 + p.y * 100);
      final haloPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 14.0 * pulse, haloPaint);
      
      // Concentric structural ring
      final ringPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, 8, ringPaint);
      
      // Crosshair ticks
      final tickPaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      const double r = 10.0;
      canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx - r + 3, center.dy), tickPaint);
      canvas.drawLine(Offset(center.dx + r - 3, center.dy), Offset(center.dx + r, center.dy), tickPaint);
      canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy - r + 3), tickPaint);
      canvas.drawLine(Offset(center.dx, center.dy + r - 3), Offset(center.dx, center.dy + r), tickPaint);
      
      // Ultra bright solid inner core
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 3.5, corePaint);
    }

    // Dynamic interactive HUD angle meter
    void drawAngleHud(PoseLandmark joint, PoseLandmark p1, PoseLandmark p2, String label, Color baseColor) {
      if (joint.likelihood < 0.5 || p1.likelihood < 0.5 || p2.likelihood < 0.5) {
        return;
      }
      
      final jCenter = scale(joint);
      final o1 = scale(p1);
      final o2 = scale(p2);
      
      final v1 = o1 - jCenter;
      final v2 = o2 - jCenter;
      
      final a1 = math.atan2(v1.dy, v1.dx);
      final a2 = math.atan2(v2.dy, v2.dx);
      
      final angleRad = (a1 - a2).abs();
      double angleDeg = angleRad * 180 / math.pi;
      if (angleDeg > 180) {
        angleDeg = 360 - angleDeg;
      }
      
      // Draw dynamic glowing HUD arc gauge
      final arcRect = Rect.fromCircle(center: jCenter, radius: 42);
      final startAngle = math.min(a1, a2);
      final sweepAngle = angleRad > math.pi ? 2 * math.pi - angleRad : angleRad;
      
      // Glowing background arc
      canvas.drawArc(
        arcRect, 
        startAngle, 
        sweepAngle, 
        false, 
        Paint()
          ..color = baseColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
      );
      
      // Neon pointer arc
      canvas.drawArc(
        arcRect, 
        startAngle, 
        sweepAngle, 
        false, 
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
      );
      
      // Bisect angle to position label neatly
      final avgAngle = (a1 + a2) / 2 + (angleRad > math.pi ? math.pi : 0);
      final textOffset = jCenter + Offset(math.cos(avgAngle), math.sin(avgAngle)) * 64;
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$label: ${angleDeg.round()}°',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Rajdhani',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: baseColor.withValues(alpha: 0.8),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Background glassmorphic chip for text
      final capPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;
      final capRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          textOffset.dx - textPainter.width / 2 - 8,
          textOffset.dy - textPainter.height / 2 - 5,
          textPainter.width + 16,
          textPainter.height + 10,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(capRect, capPaint);
      
      // Glass border
      canvas.drawRRect(
        capRect, 
        Paint()
          ..color = baseColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
      );
      
      textPainter.paint(
        canvas, 
        Offset(textOffset.dx - textPainter.width / 2, textOffset.dy - textPainter.height / 2)
      );
    }

    // Rotating bracket nose scanner
    void drawNoseLock(PoseLandmark nosePoint, Color baseColor) {
      if (nosePoint.likelihood < 0.5) {
        return;
      }
      final center = scale(nosePoint);
      final angle = (DateTime.now().millisecondsSinceEpoch / 900.0) % (2 * math.pi);
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      
      final paint = Paint()
        ..color = baseColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      const double size = 18.0;
      const double g = 6.0;
      
      // 4 brackets [ ]
      canvas.drawLine(const Offset(-size, -size), const Offset(-size + g, -size), paint);
      canvas.drawLine(const Offset(-size, -size), const Offset(-size, -size + g), paint);
      
      canvas.drawLine(const Offset(size, -size), const Offset(size - g, -size), paint);
      canvas.drawLine(const Offset(size, -size), const Offset(size, -size + g), paint);
      
      canvas.drawLine(const Offset(-size, size), const Offset(-size + g, size), paint);
      canvas.drawLine(const Offset(-size, size), const Offset(-size, size - g), paint);
      
      canvas.drawLine(const Offset(size, size), const Offset(size - g, size), paint);
      canvas.drawLine(const Offset(size, size), const Offset(size, size - g), paint);
      
      // Small core reticle dot
      canvas.drawCircle(Offset.zero, 3.0, Paint()..color = baseColor..style = PaintingStyle.fill);
      canvas.restore();
    }

    // Torso balance leveler HUD
    void drawTorsoHoop(Color baseColor) {
      if (pose!.leftShoulder.likelihood < 0.5 || pose!.rightShoulder.likelihood < 0.5 ||
          pose!.leftHip.likelihood < 0.5 || pose!.rightHip.likelihood < 0.5) {
        return;
      }
      
      final ls = scale(pose!.leftShoulder);
      final rs = scale(pose!.rightShoulder);
      final lh = scale(pose!.leftHip);
      final rh = scale(pose!.rightHip);
      
      final coreCenter = Offset(
        (ls.dx + rs.dx + lh.dx + rh.dx) / 4,
        (ls.dy + rs.dy + lh.dy + rh.dy) / 4,
      );
      
      // Outer radar scanning bounds
      canvas.drawCircle(coreCenter, 20.0, Paint()..color = baseColor.withValues(alpha: 0.18)..style = PaintingStyle.fill);
      canvas.drawCircle(
        coreCenter, 20.0, 
        Paint()..color = baseColor.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0
      );
      canvas.drawCircle(
        coreCenter, 26.0, 
        Paint()..color = baseColor.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1.0
      );
      
      // Core crosshairs
      final crossPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(coreCenter.dx - 30, coreCenter.dy), Offset(coreCenter.dx - 22, coreCenter.dy), crossPaint);
      canvas.drawLine(Offset(coreCenter.dx + 22, coreCenter.dy), Offset(coreCenter.dx + 30, coreCenter.dy), crossPaint);
      canvas.drawLine(Offset(coreCenter.dx, coreCenter.dy - 30), Offset(coreCenter.dx, coreCenter.dy - 22), crossPaint);
      canvas.drawLine(Offset(coreCenter.dx, coreCenter.dy + 22), Offset(coreCenter.dx, coreCenter.dy + 30), crossPaint);
    }

    // 1. Draw BONES (Lines) with glowing laser neon shaders
    // Upper Body
    drawNeonLine(pose!.leftShoulder, pose!.rightShoulder, hudColor);
    drawNeonLine(pose!.leftShoulder, pose!.leftElbow, hudColor);
    drawNeonLine(pose!.leftElbow, pose!.leftWrist, hudColor);
    drawNeonLine(pose!.rightShoulder, pose!.rightElbow, hudColor);
    drawNeonLine(pose!.rightElbow, pose!.rightWrist, hudColor);

    // Torso
    drawNeonLine(pose!.leftShoulder, pose!.leftHip, hudColor);
    drawNeonLine(pose!.rightShoulder, pose!.rightHip, hudColor);
    drawNeonLine(pose!.leftHip, pose!.rightHip, hudColor);

    // Lower Body
    drawNeonLine(pose!.leftHip, pose!.leftKnee, hudColor);
    drawNeonLine(pose!.leftKnee, pose!.leftAnkle, hudColor);
    drawNeonLine(pose!.rightHip, pose!.rightKnee, hudColor);
    drawNeonLine(pose!.rightKnee, pose!.rightAnkle, hudColor);

    // 2. Draw NODES (Joint points) with crosshairs and pulsing halos
    drawCyberJoint(pose!.leftShoulder, hudColor);
    drawCyberJoint(pose!.rightShoulder, hudColor);
    drawCyberJoint(pose!.leftElbow, hudColor);
    drawCyberJoint(pose!.rightElbow, hudColor);
    drawCyberJoint(pose!.leftWrist, hudColor);
    drawCyberJoint(pose!.rightWrist, hudColor);
    drawCyberJoint(pose!.leftHip, hudColor);
    drawCyberJoint(pose!.rightHip, hudColor);
    drawCyberJoint(pose!.leftKnee, hudColor);
    drawCyberJoint(pose!.rightKnee, hudColor);
    drawCyberJoint(pose!.leftAnkle, hudColor);
    drawCyberJoint(pose!.rightAnkle, hudColor);

    // 3. Draw Cyber Reticles (Nose / Core)
    drawNoseLock(pose!.nose, hudColor);
    drawTorsoHoop(hudColor);

    // 4. Draw real-time Interactive Angle Gauges
    switch (exerciseType.toLowerCase()) {
      case 'squat':
      case 'sumo_squat':
        drawAngleHud(pose!.leftKnee, pose!.leftHip, pose!.leftAnkle, 'KNEE_L', hudColor);
        drawAngleHud(pose!.rightKnee, pose!.rightHip, pose!.rightAnkle, 'KNEE_R', hudColor);
        break;
      case 'pushup':
      case 'push-up':
      case 'diamond_pushup':
        drawAngleHud(pose!.leftElbow, pose!.leftShoulder, pose!.leftWrist, 'ELBOW_L', hudColor);
        drawAngleHud(pose!.rightElbow, pose!.rightShoulder, pose!.rightWrist, 'ELBOW_R', hudColor);
        break;
      case 'plank':
        drawAngleHud(pose!.leftHip, pose!.leftShoulder, pose!.leftKnee, 'CORE_L', hudColor);
        drawAngleHud(pose!.rightHip, pose!.rightShoulder, pose!.rightKnee, 'CORE_R', hudColor);
        break;
      default:
        break;
    }

    // 5. Build Immersive Positioning Setup Overlay if in pre-flight calibration
    if (isSetupPhase) {
      _drawHolographicSilhouette(canvas, size);

      final cx = size.width / 2;
      final targets = {
        'NOSE': Offset(cx, size.height * 0.22),
        'SHOULDER_L': Offset(cx - size.width * 0.12, size.height * 0.32),
        'SHOULDER_R': Offset(cx + size.width * 0.12, size.height * 0.32),
        'HIP_L': Offset(cx - size.width * 0.10, size.height * 0.55),
        'HIP_R': Offset(cx + size.width * 0.10, size.height * 0.55),
        'ANKLE_L': Offset(cx - size.width * 0.10, size.height * 0.88),
        'ANKLE_R': Offset(cx + size.width * 0.10, size.height * 0.88),
      };
      
      final joints = {
        'NOSE': pose!.nose,
        'SHOULDER_L': pose!.leftShoulder,
        'SHOULDER_R': pose!.rightShoulder,
        'HIP_L': pose!.leftHip,
        'HIP_R': pose!.rightHip,
        'ANKLE_L': pose!.leftAnkle,
        'ANKLE_R': pose!.rightAnkle,
      };

      targets.forEach((key, targetOffset) {
        final joint = joints[key];
        if (joint == null || joint.likelihood < 0.5) {
          return;
        }
        final jointOffset = scale(joint);
        
        final distance = (jointOffset - targetOffset).distance;
        final isLocked = distance < size.width * 0.08;
        final lockColor = isLocked ? const Color(0xFF00FF88) : const Color(0xFFFF9900);
        
        // Target lock radar hoop
        canvas.drawCircle(targetOffset, 20, Paint()..color = lockColor.withValues(alpha: 0.1)..style = PaintingStyle.fill);
        canvas.drawCircle(
          targetOffset, 20, 
          Paint()..color = lockColor.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1.0
        );
        
        // Draw locked tracking visual lines
        if (distance < size.width * 0.22) {
          canvas.drawLine(
            jointOffset, targetOffset, 
            Paint()..color = lockColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0..strokeCap = StrokeCap.round
          );
        }
        
        if (isLocked) {
          final pulse = 1.0 + 0.1 * math.sin(DateTime.now().millisecondsSinceEpoch / 150.0);
          final r = 24.0 * pulse;
          final bracketPaint = Paint()
            ..color = const Color(0xFF00FF88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
            
          canvas.drawArc(Rect.fromCircle(center: targetOffset, radius: r), -0.4, 0.8, false, bracketPaint);
          canvas.drawArc(Rect.fromCircle(center: targetOffset, radius: r), math.pi - 0.4, 0.8, false, bracketPaint);
          
          final textPainter = TextPainter(
            text: const TextSpan(
              text: 'LOCKED',
              style: TextStyle(
                color: Color(0xFF00FF88),
                fontFamily: 'Rajdhani',
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(targetOffset.dx - textPainter.width / 2, targetOffset.dy + 25));
        }
      });
      
      // Lateral positioning indicator chevrons
      final avgHipX = (scale(pose!.leftHip).dx + scale(pose!.rightHip).dx) / 2;
      final normalizedX = avgHipX / size.width;
      
      if (normalizedX < 0.4) {
        _drawChevronChevrons(canvas, size, pointingRight: true);
      } else if (normalizedX > 0.6) {
        _drawChevronChevrons(canvas, size, pointingRight: false);
      }
    }
  }

  // Draw neutral human body silhouette template wireframe
  void _drawHolographicSilhouette(Canvas canvas, Size size) {
    final pulse = 0.65 + 0.35 * math.sin(DateTime.now().millisecondsSinceEpoch / 400.0);
    final paint = Paint()
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.15 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    final cx = size.width / 2;
    final head = Offset(cx, size.height * 0.22);
    final lShoulder = Offset(cx - size.width * 0.12, size.height * 0.32);
    final rShoulder = Offset(cx + size.width * 0.12, size.height * 0.32);
    final lHip = Offset(cx - size.width * 0.10, size.height * 0.55);
    final rHip = Offset(cx + size.width * 0.10, size.height * 0.55);
    final lKnee = Offset(cx - size.width * 0.10, size.height * 0.72);
    final rKnee = Offset(cx + size.width * 0.10, size.height * 0.72);
    final lAnkle = Offset(cx - size.width * 0.10, size.height * 0.88);
    final rAnkle = Offset(cx + size.width * 0.10, size.height * 0.88);

    canvas.drawCircle(head, 28, paint);
    canvas.drawArc(Rect.fromCircle(center: head, radius: 36), -0.5, 1.0, false, paint);
    canvas.drawArc(Rect.fromCircle(center: head, radius: 36), math.pi - 0.5, 1.0, false, paint);

    // Spine and Torso
    canvas.drawLine(lShoulder, rShoulder, paint);
    canvas.drawLine(lShoulder, lHip, paint);
    canvas.drawLine(rShoulder, rHip, paint);
    canvas.drawLine(lHip, rHip, paint);

    // Limbs
    canvas.drawLine(lHip, lKnee, paint);
    canvas.drawLine(lKnee, lAnkle, paint);
    canvas.drawLine(rHip, rKnee, paint);
    canvas.drawLine(rKnee, rAnkle, paint);
    
    // Arm lines
    final lElbow = Offset(cx - size.width * 0.20, size.height * 0.42);
    final rElbow = Offset(cx + size.width * 0.20, size.height * 0.42);
    final lWrist = Offset(cx - size.width * 0.22, size.height * 0.52);
    final rWrist = Offset(cx + size.width * 0.22, size.height * 0.52);
    
    canvas.drawLine(lShoulder, lElbow, paint);
    canvas.drawLine(lElbow, lWrist, paint);
    canvas.drawLine(rShoulder, rElbow, paint);
    canvas.drawLine(rElbow, rWrist, paint);
  }

  // Draw animated chevrons showing lateral guidance vectors
  void _drawChevronChevrons(Canvas canvas, Size size, {required bool pointingRight}) {
    final animFrame = (DateTime.now().millisecondsSinceEpoch / 250) % 3;
    final paint = Paint()
      ..color = const Color(0xFFFF9900)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    final y = size.height * 0.5;
    final startX = pointingRight ? 40.0 : size.width - 40.0;
    const double spacing = 14.0;
    final double dir = pointingRight ? 1.0 : -1.0;
    
    for (int i = 0; i < 3; i++) {
      final double alpha = (i == animFrame.toInt()) ? 1.0 : 0.25;
      paint.color = const Color(0xFFFF9900).withValues(alpha: alpha);
      
      final cx = startX + i * spacing * dir;
      final path = Path()
        ..moveTo(cx - 5 * dir, y - 12)
        ..lineTo(cx + 5 * dir, y)
        ..lineTo(cx - 5 * dir, y + 12);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return pose != oldDelegate.pose || 
           accuracy != oldDelegate.accuracy || 
           isSetupPhase != oldDelegate.isSetupPhase ||
           calibrationProgress != oldDelegate.calibrationProgress;
  }
}
