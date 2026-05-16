import 'dart:async';
import 'dart:io' show Platform;
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
          _feedbackColor = envStatus.isValid ? const Color(0xFF00FF88) : const Color(0xFFFF6B35);
          _feedbackMessage = envStatus.message;
          _feedbackColor = const Color(0xFFFF6B35);
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
    if (_currentPose == null || _imageSize == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size.infinite,
      painter: PoseOverlayPainter(
        pose: _currentPose,
        accuracy: _accuracy,
        imageSize: _imageSize!,
        isFrontCamera: _currentCameraFacing == CameraLensDirection.front,
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

/// 🎨 Pose Overlay Painter
class PoseOverlayPainter extends CustomPainter {
  final PoseLandmarks? pose;
  final double accuracy;
  final Size imageSize;
  final bool isFrontCamera;

  PoseOverlayPainter({
    required this.pose,
    required this.accuracy,
    required this.imageSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) {
      return;
    }

    // Modern color palette for feedback
    final Color strokeColor = accuracy >= 95 
        ? const Color(0xFF00FF88) // Perfect Green
        : accuracy >= 80 
            ? const Color(0xFF00D9FF) // Good Blue
            : const Color(0xFFFF6B35); // Warning Orange

    final paint = Paint()
      ..color = strokeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final landmarkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Offset scale(PoseLandmark p) {
      // Accurate scaling using image dimensions vs view dimensions
      // Note: Camera image might be rotated
      double x = p.x * size.width / imageSize.width;
      double y = p.y * size.height / imageSize.height;
      
      if (isFrontCamera) {
        x = size.width - x;
      }
      
      return Offset(x, y);
    }

    void drawLine(PoseLandmark p1, PoseLandmark p2) {
      if (p1.likelihood > 0.5 && p2.likelihood > 0.5) {
        canvas.drawLine(scale(p1), scale(p2), paint);
      }
    }

    void drawPoint(PoseLandmark p) {
      if (p.likelihood > 0.5) {
        canvas.drawCircle(scale(p), 4, landmarkPaint);
      }
    }

    // Draw Skeleton Lines
    // Upper Body
    drawLine(pose!.leftShoulder, pose!.rightShoulder);
    drawLine(pose!.leftShoulder, pose!.leftElbow);
    drawLine(pose!.leftElbow, pose!.leftWrist);
    drawLine(pose!.rightShoulder, pose!.rightElbow);
    drawLine(pose!.rightElbow, pose!.rightWrist);

    // Torso
    drawLine(pose!.leftShoulder, pose!.leftHip);
    drawLine(pose!.rightShoulder, pose!.rightHip);
    drawLine(pose!.leftHip, pose!.rightHip);

    // Lower Body
    drawLine(pose!.leftHip, pose!.leftKnee);
    drawLine(pose!.leftKnee, pose!.leftAnkle);
    drawLine(pose!.rightHip, pose!.rightKnee);
    drawLine(pose!.rightKnee, pose!.rightAnkle);

    // Draw Landmark Points
    drawPoint(pose!.leftShoulder);
    drawPoint(pose!.rightShoulder);
    drawPoint(pose!.leftElbow);
    drawPoint(pose!.rightElbow);
    drawPoint(pose!.leftWrist);
    drawPoint(pose!.rightWrist);
    drawPoint(pose!.leftHip);
    drawPoint(pose!.rightHip);
    drawPoint(pose!.leftKnee);
    drawPoint(pose!.rightKnee);
    drawPoint(pose!.leftAnkle);
    drawPoint(pose!.rightAnkle);
    drawPoint(pose!.nose);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return pose != oldDelegate.pose || accuracy != oldDelegate.accuracy;
  }
}
