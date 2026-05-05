import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'flutter_tts_provider.dart';
import 'tts_provider.dart';
import '../voice/voice_script_manager.dart';

/// Priority levels for voice messages
enum VoicePriority {
  high, // Injury alerts, critical warnings
  normal, // Form feedback, rep counts
  low, // Encouragement, general feedback
}

/// Voice message with priority
class VoiceMessage {
  final String text;
  final VoicePriority priority;
  final DateTime timestamp;

  VoiceMessage({
    required this.text,
    this.priority = VoicePriority.normal,
  }) : timestamp = DateTime.now();
}

/// Real-time voice feedback service for workout guidance
///
/// Provides audio cues during exercises including:
/// - Form corrections
/// - Rep count announcements
/// - Countdown timers
/// - Motivational feedback
///
/// Features:
/// - Message queue to prevent overlapping speech
/// - Duplicate message filtering
/// - Configurable voice settings
/// - Priority-based queueing
class VoiceFeedbackService {
  static final VoiceFeedbackService _instance =
      VoiceFeedbackService._internal();
  factory VoiceFeedbackService() => _instance;

  VoiceFeedbackService._internal();

  TTSProvider _provider = FlutterTTSProvider();
  final Queue<VoiceMessage> _messageQueue = Queue<VoiceMessage>();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isEnabled = true;

  // Settings optimized for a motivational, natural, and energetic tone
  double _volume = 1.0;
  double _pitch = 1.15; // Slightly elevated for higher energy/motivation
  double _rate = 0.55; // Natural conversational pace (less robotic than 0.5)
  String _language = 'en-US';
  String _locale = 'en';

  // Duplicate prevention
  final Map<String, DateTime> _recentMessages = {};
  final Duration _duplicateWindow = const Duration(seconds: 3);

  // Minimum gap between messages
  DateTime? _lastSpeechTime;
  final Duration _minGapBetweenMessages = const Duration(seconds: 2);

  /// Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      if (_provider is FlutterTTSProvider) {
        final flutterProvider = _provider as FlutterTTSProvider;
        flutterProvider.setCompletionHandler(() {
          _isSpeaking = false;
          unawaited(_processQueue());
        });

        flutterProvider.setErrorHandler((msg) {
          debugPrint('TTS Error: $msg');
          _isSpeaking = false;
          unawaited(_processQueue());
        });
      }

      await _provider.initialize();

      // Configure default settings
      await _provider.setSettings(
        language: _language,
        volume: _volume,
        pitch: _pitch,
        rate: _rate,
      );

      _isInitialized = true;
      debugPrint(
          'Voice Feedback Service initialized with provider: ${_provider.runtimeType}');
    } catch (e) {
      debugPrint('Failed to initialize TTS provider: $e');
    }
  }

  /// Speak a message with queueing and duplicate prevention
  Future<void> speak(String message,
      {VoicePriority priority = VoicePriority.normal}) async {
    if (!_isEnabled || !_isInitialized) {
      return;
    }
    if (message.isEmpty) {
      return;
    }

    // Check for duplicate messages
    if (_isDuplicate(message)) {
      debugPrint('Skipping duplicate message: $message');
      return;
    }

    // Add to queue
    final voiceMessage = VoiceMessage(text: message, priority: priority);

    if (priority == VoicePriority.high) {
      // High priority messages go to front of queue
      _messageQueue.addFirst(voiceMessage);
    } else {
      _messageQueue.add(voiceMessage);
    }

    // Record message to prevent duplicates
    _recentMessages[message] = DateTime.now();

    // Start processing if not already speaking
    if (!_isSpeaking) {
      unawaited(_processQueue());
    }
  }

  /// Process the message queue
  Future<void> _processQueue() async {
    if (_messageQueue.isEmpty || _isSpeaking) {
      return;
    }

    // Check minimum gap between messages
    if (_lastSpeechTime != null) {
      final timeSinceLastSpeech = DateTime.now().difference(_lastSpeechTime!);
      if (timeSinceLastSpeech < _minGapBetweenMessages) {
        // Wait for the remaining time
        final waitTime = _minGapBetweenMessages - timeSinceLastSpeech;
        await Future.delayed(waitTime);
      }
    }

    final message = _messageQueue.removeFirst();
    _isSpeaking = true;
    _lastSpeechTime = DateTime.now();

    try {
      await _provider.speak(message.text);

      // For providers that don't support completion callbacks,
      // we might need a timeout or manual reset.
      // On-device TTS usually has native callbacks handled in initialize.
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
      unawaited(_processQueue());
    }
  }

  /// Check if message is a duplicate
  bool _isDuplicate(String message) {
    final lastTime = _recentMessages[message];
    if (lastTime == null) {
      return false;
    }

    final timeSince = DateTime.now().difference(lastTime);
    return timeSince < _duplicateWindow;
  }

  /// Provide form feedback based on accuracy
  Future<void> provideFormFeedback(
      double accuracy, List<String> failedCriteria) async {
    if (accuracy >= 90) {
      await speak('Excellent form!', priority: VoicePriority.normal);
    } else if (accuracy >= 75) {
      await speak('Good job, keep it up!', priority: VoicePriority.low);
    } else if (failedCriteria.isNotEmpty) {
      // Provide specific feedback for the first failed criterion
      final feedback = _getFormCorrection(failedCriteria.first);
      if (feedback != null) {
        await speak(feedback, priority: VoicePriority.normal);
      }
    }
  }

  /// Get specific form correction message
  String? _getFormCorrection(String criterion) {
    return VoiceScriptManager.getFormCorrection(_locale, criterion);
  }

  /// Announce rep count milestone
  Future<void> announceRepCount(int reps, int? target) async {
    if (reps % 5 == 0) {
      if (target != null && reps == target ~/ 2) {
        await speak('$reps ${VoiceScriptManager.getRepMilestone5(_locale)}',
            priority: VoicePriority.normal);
      } else {
        await speak('$reps ${VoiceScriptManager.getRepComplete(_locale)}',
            priority: VoicePriority.normal);
      }
    }

    if (target != null && reps == target) {
      await speak(VoiceScriptManager.getSessionComplete(_locale),
          priority: VoicePriority.normal);
    }
  }

  /// Countdown timer (3, 2, 1, Go!)
  Future<void> countdown() async {
    await speak(VoiceScriptManager.getSessionStart(_locale),
        priority: VoicePriority.high);
  }

  /// Provide tempo feedback
  Future<void> provideTempoFeedback(String feedback) async {
    final message = VoiceScriptManager.getTempoFeedback(_locale, feedback);
    if (message != null) {
      await speak(message, priority: VoicePriority.normal);
    }
  }

  /// Provide encouragement
  Future<void> encourage() async {
    final encouragements = VoiceScriptManager.getEncouragement(_locale);

    final message =
        encouragements[DateTime.now().second % encouragements.length];
    await speak(message, priority: VoicePriority.low);
  }

  /// Alert for injury risk
  Future<void> alertInjuryRisk(String warning) async {
    await speak('Warning: $warning', priority: VoicePriority.high);
  }

  /// Announce workout completion
  Future<void> announceWorkoutComplete(
      int totalReps, double avgAccuracy) async {
    await speak(
      'Workout complete! $totalReps reps with ${avgAccuracy.toInt()}% accuracy',
      priority: VoicePriority.high,
    );
  }

  /// Configure voice settings
  Future<void> setVoice({
    String? language,
    double? pitch,
    double? rate,
    double? volume,
  }) async {
    if (language != null) {
      _language = language;
    }

    if (pitch != null) {
      _pitch = pitch;
    }

    if (rate != null) {
      _rate = rate;
    }

    _locale = language?.split('-')[0] ?? _locale;

    if (volume != null) {
      _volume = volume;
    }

    await _provider.setSettings(
      language: language,
      pitch: pitch,
      rate: rate,
      volume: volume,
    );
  }

  /// Enable/disable voice feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  /// Check if voice is enabled
  bool get isEnabled => _isEnabled;

  /// Stop current speech
  Future<void> stop() async {
    await _provider.stop();
    _isSpeaking = false;
    _messageQueue.clear();
  }

  /// Switch provider at runtime (e.g. from local to ElevenLabs)
  Future<void> switchProvider(TTSProvider newProvider) async {
    await _provider.dispose();
    _provider = newProvider;
    _isInitialized = false;
    await initialize();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    await _provider.dispose();
    _messageQueue.clear();
    _recentMessages.clear();
  }
}
