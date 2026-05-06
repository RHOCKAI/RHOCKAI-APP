import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'flutter_tts_provider.dart';
import 'tts_provider.dart';
import '../voice/voice_script_manager.dart';
import '../../../core/providers/settings_provider.dart';

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

  double _volume = 1.0;
  double _pitch = 1.15;
  double _rate = 0.55;
  String _language = 'en-US';
  String _locale = 'en';
  VoicePersonality _personality = VoicePersonality.natural;

  final Map<String, DateTime> _recentMessages = {};
  final Duration _duplicateWindow = const Duration(seconds: 3);
  DateTime? _lastSpeechTime;
  final Duration _minGapBetweenMessages = const Duration(seconds: 2);

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
      await _provider.setSettings(
        language: _language,
        volume: _volume,
        pitch: _pitch,
        rate: _rate,
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize TTS provider: $e');
    }
  }

  Future<void> speak(String message,
      {VoicePriority priority = VoicePriority.normal}) async {
    if (!_isEnabled || !_isInitialized) {
      return;
    }
    if (message.isEmpty) {
      return;
    }

    if (_isDuplicate(message)) {
      return;
    }

    final voiceMessage = VoiceMessage(text: message, priority: priority);
    if (priority == VoicePriority.high) {
      _messageQueue.addFirst(voiceMessage);
    } else {
      _messageQueue.add(voiceMessage);
    }

    _recentMessages[message] = DateTime.now();
    if (!_isSpeaking) {
      unawaited(_processQueue());
    }
  }

  Future<void> _processQueue() async {
    if (_messageQueue.isEmpty || _isSpeaking) {
      return;
    }

    if (_lastSpeechTime != null) {
      final timeSinceLastSpeech = DateTime.now().difference(_lastSpeechTime!);
      if (timeSinceLastSpeech < _minGapBetweenMessages) {
        final waitTime = _minGapBetweenMessages - timeSinceLastSpeech;
        await Future.delayed(waitTime);
      }
    }

    if (_messageQueue.isEmpty) {
      return;
    }
    
    final message = _messageQueue.removeFirst();
    _isSpeaking = true;
    _lastSpeechTime = DateTime.now();

    try {
      await _provider.speak(message.text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _isSpeaking = false;
      unawaited(_processQueue());
    }
  }

  bool _isDuplicate(String message) {
    final lastTime = _recentMessages[message];
    if (lastTime == null) {
      return false;
    }
    return DateTime.now().difference(lastTime) < _duplicateWindow;
  }

  Future<void> provideFormFeedback(
      double accuracy, List<String> failedCriteria, {String? perfectionTip}) async {
    if (accuracy >= 95 && perfectionTip != null) {
      await speak(perfectionTip, priority: VoicePriority.normal);
    } else if (accuracy >= 90) {
      final message = VoiceScriptManager.getExcellentForm(_locale, _personality);
      await speak(message, priority: VoicePriority.normal);
    } else if (accuracy >= 75) {
      final message = VoiceScriptManager.getGoodJob(_locale, _personality);
      await speak(message, priority: VoicePriority.low);
    } else if (failedCriteria.isNotEmpty) {
      final feedback = _getFormCorrection(failedCriteria.first);
      if (feedback != null) {
        await speak(feedback, priority: VoicePriority.normal);
      }
    }
  }

  String? _getFormCorrection(String criterion) {
    return VoiceScriptManager.getFormCorrection(_locale, criterion, _personality);
  }

  Future<void> announceRepCount(int reps, int? target) async {
    if (reps % 5 == 0) {
      if (target != null && reps == target ~/ 2) {
        final milestone = VoiceScriptManager.getRepMilestone5(_locale, _personality);
        await speak('$reps $milestone', priority: VoicePriority.normal);
      } else {
        final complete = VoiceScriptManager.getRepComplete(_locale, _personality);
        await speak('$reps $complete', priority: VoicePriority.normal);
      }
    }

    if (target != null && reps == target) {
      final message = VoiceScriptManager.getSessionComplete(_locale, _personality);
      await speak(message, priority: VoicePriority.normal);
    }
  }

  Future<void> countdown() async {
    final message = VoiceScriptManager.getSessionStart(_locale, _personality);
    await speak(message, priority: VoicePriority.high);
  }

  Future<void> provideTempoFeedback(String feedback) async {
    final message = VoiceScriptManager.getTempoFeedback(_locale, feedback, _personality);
    if (message != null) {
      await speak(message, priority: VoicePriority.normal);
    }
  }

  Future<void> encourage() async {
    final encouragements = VoiceScriptManager.getEncouragement(_locale, _personality);
    final message = encouragements[DateTime.now().second % encouragements.length];
    await speak(message, priority: VoicePriority.low);
  }

  Future<void> alertInjuryRisk(String warning) async {
    final prefix = VoiceScriptManager.getWarningPrefix(_locale, _personality);
    await speak('$prefix: $warning', priority: VoicePriority.high);
  }

  Future<void> announceWorkoutComplete(int totalReps, double avgAccuracy) async {
    final message = VoiceScriptManager.getWorkoutCompleteSummary(
      _locale, _personality, totalReps, avgAccuracy.toInt()
    );
    await speak(message, priority: VoicePriority.high);
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      unawaited(stop());
    }
  }

  Future<void> setVoice({
    String? language,
    double? pitch,
    double? rate,
    double? volume,
    VoicePersonality? personality,
  }) async {
    if (language != null) {
      _language = language;
      _locale = language.split('-')[0];
    }
    
    if (personality != null) {
      _personality = personality;
      switch (personality) {
        case VoicePersonality.sergeant:
          _pitch = 0.85; 
          _rate = 0.65; 
          _volume = 1.0;
          break;
        case VoicePersonality.zen:
          _pitch = 1.0; 
          _rate = 0.45; 
          _volume = 0.8;
          break;
        case VoicePersonality.hype:
          _pitch = 1.3; 
          _rate = 0.7; 
          _volume = 1.0;
          break;
        case VoicePersonality.natural:
          _pitch = 1.15; 
          _rate = 0.55; 
          _volume = 1.0;
          break;
      }
    }

    if (pitch != null) {
      _pitch = pitch;
    }
    if (rate != null) {
      _rate = rate;
    }
    if (volume != null) {
      _volume = volume;
    }

    if (_isInitialized) {
      await _provider.setSettings(
        language: _language,
        pitch: _pitch,
        rate: _rate,
        volume: _volume,
      );
    }
  }

  bool get isEnabled => _isEnabled;

  Future<void> stop() async {
    await _provider.stop();
    _isSpeaking = false;
    _messageQueue.clear();
  }

  Future<void> switchProvider(TTSProvider newProvider) async {
    await _provider.dispose();
    _provider = newProvider;
    _isInitialized = false;
    await initialize();
  }

  Future<void> dispose() async {
    await stop();
    await _provider.dispose();
  }
}
