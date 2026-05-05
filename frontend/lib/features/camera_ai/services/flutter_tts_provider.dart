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
      await _setHighQualityVoice(language);
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

  /// Attempts to find and set the highest quality, most natural voice available
  /// for the selected language, prioritizing network voices (less robotic).
  Future<void> _setHighQualityVoice(String languageCode) async {
    try {
      final List<dynamic>? voices = await _tts.getVoices;
      if (voices == null || voices.isEmpty) return;

      // Filter voices matching the requested language
      final availableVoices = voices.where((v) {
        final locale = v['locale']?.toString() ?? '';
        return locale.startsWith(languageCode.split('-').first);
      }).toList();

      if (availableVoices.isEmpty) return;

      Map<String, String>? bestVoice;

      for (dynamic v in availableVoices) {
        final name = v['name']?.toString().toLowerCase() ?? '';
        
        // Android: Network voices are Google's cloud TTS (highly natural/motivational)
        // iOS: Premium/Enhanced voices sound much less robotic
        if (name.contains('network') || name.contains('premium') || name.contains('enhanced')) {
          bestVoice = {"name": v["name"].toString(), "locale": v["locale"].toString()};
          break; // Found a high-quality voice
        }
      }

      // Fallback: If no network voice, just pick the first one matching the locale
      bestVoice ??= {
        "name": availableVoices.first["name"].toString(),
        "locale": availableVoices.first["locale"].toString()
      };

      await _tts.setVoice(bestVoice);
    } catch (e) {
      debugPrint('Failed to set high quality voice: $e');
    }
  }

  /// Hook for the VoiceFeedbackService to manage completion state
  void setCompletionHandler(Function() onComplete) {
    _tts.setCompletionHandler(onComplete);
  }

  void setErrorHandler(Function(dynamic) onError) {
    _tts.setErrorHandler(onError);
  }
}
