import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice settings model for TTS configuration
class VoiceSettings {
  final bool enabled;
  final String language;
  final String locale;
  final double pitch;
  final double rate;
  final double volume;
  final bool announceReps;
  final bool announceForm;
  final bool announceEncouragement;

  const VoiceSettings({
    this.enabled = true,
    this.language = 'en-US',
    this.locale = 'en',
    this.pitch = 1.0,
    this.rate = 0.5,
    this.volume = 0.8,
    this.announceReps = true,
    this.announceForm = true,
    this.announceEncouragement = true,
  });

  /// Copy with modifications
  VoiceSettings copyWith({
    bool? enabled,
    String? language,
    String? locale,
    double? pitch,
    double? rate,
    double? volume,
    bool? announceReps,
    bool? announceForm,
    bool? announceEncouragement,
  }) {
    return VoiceSettings(
      enabled: enabled ?? this.enabled,
      language: language ?? this.language,
      locale: locale ?? this.locale,
      pitch: pitch ?? this.pitch,
      rate: rate ?? this.rate,
      volume: volume ?? this.volume,
      announceReps: announceReps ?? this.announceReps,
      announceForm: announceForm ?? this.announceForm,
      announceEncouragement:
          announceEncouragement ?? this.announceEncouragement,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'language': language,
      'locale': locale,
      'pitch': pitch,
      'rate': rate,
      'volume': volume,
      'announceReps': announceReps,
      'announceForm': announceForm,
      'announceEncouragement': announceEncouragement,
    };
  }

  /// Create from JSON
  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      enabled: json['enabled'] ?? true,
      language: json['language'] ?? 'en-US',
      locale: json['locale'] ?? 'en',
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.5,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      announceReps: json['announceReps'] ?? true,
      announceForm: json['announceForm'] ?? true,
      announceEncouragement: json['announceEncouragement'] ?? true,
    );
  }

  /// Save to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_settings', jsonEncode(toJson()));
  }

  /// Load from SharedPreferences
  static Future<VoiceSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('voice_settings');

      if (jsonString != null) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return VoiceSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Failed to load voice settings: $e');
    }

    return const VoiceSettings();
  }
}
