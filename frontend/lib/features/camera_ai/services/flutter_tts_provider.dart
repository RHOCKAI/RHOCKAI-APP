import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_provider.dart';

/// On-device implementation using flutter_tts
class FlutterTTSProvider implements TTSProvider {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> initialize() async {
    // Shared audio session (iOS) — must be set before anything else
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

    // Apply sensible defaults so first speech never uses system defaults
    await _tts.setSpeechRate(0.6);
    await _tts.setPitch(1.1);
    await _tts.setVolume(1.0);
    await _tts.setLanguage('en-US');
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
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('FlutterTTS stop error: $e');
    }
  }

  @override
  Future<void> setSettings({
    String? language,
    double? pitch,
    double? rate,
    double? volume,
  }) async {
    // Stop current speech before changing language — prevents engine glitches
    if (language != null) {
      try {
        await _tts.stop();
      } catch (_) {}
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

  /// Finds the best available voice for the language, preferring:
  /// 1. Network/cloud voices (Google TTS on Android — most natural)
  /// 2. Premium/Enhanced voices (iOS)
  /// 3. First voice matching the locale as a fallback
  Future<void> _setHighQualityVoice(String languageCode) async {
    try {
      final List<dynamic>? voices = await _tts.getVoices;
      if (voices == null || voices.isEmpty) {
        return;
      }

      final langPrefix = languageCode.split('-').first.toLowerCase();

      final availableVoices = voices.where((v) {
        final locale = (v['locale']?.toString() ?? '').toLowerCase();
        // Match either 'en' prefix or exact locale like 'en-us'
        return locale.startsWith(langPrefix) ||
            locale.replaceAll('_', '-').startsWith(langPrefix);
      }).toList();

      if (availableVoices.isEmpty) {
        return;
      }

      Map<String, String>? bestVoice;

      // Priority: network > premium > enhanced > any
      for (final priority in ['network', 'premium', 'enhanced']) {
        for (final v in availableVoices) {
          final name = (v['name']?.toString() ?? '').toLowerCase();
          if (name.contains(priority)) {
            bestVoice = {
              'name': v['name'].toString(),
              'locale': v['locale'].toString(),
            };
            break;
          }
        }
        if (bestVoice != null) {
          break;
        }
      }

      // Fallback: first voice matching the locale
      bestVoice ??= {
        'name': availableVoices.first['name'].toString(),
        'locale': availableVoices.first['locale'].toString(),
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
