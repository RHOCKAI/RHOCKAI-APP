import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_provider.dart';

/// On-device implementation using flutter_tts
class FlutterTTSProvider implements TTSProvider {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> initialize() async {
    // Basic flutter_tts configuration
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('FlutterTTS error: $e');
    }
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> setSettings({
    String? language,
    double? pitch,
    double? rate,
    double? volume,
  }) async {
    if (language != null) {
      await _tts.setLanguage(language);
    }
    if (pitch != null) {
      await _tts.setPitch(pitch);
    }
    if (rate != null) {
      await _tts.setSpeechRate(rate);
    }
    if (volume != null) {
      await _tts.setVolume(volume);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
  }

  /// Hook for the VoiceFeedbackService to manage completion state
  void setCompletionHandler(Function() onComplete) {
    _tts.setCompletionHandler(onComplete);
  }

  void setErrorHandler(Function(dynamic) onError) {
    _tts.setErrorHandler(onError);
  }
}
