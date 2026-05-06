import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

enum WorkoutCommand {
  start,
  stop,
  pause,
  resume,
  next,
  previous,
  unknown,
}

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;

  VoiceCommandService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _locale = 'en-US';
  Function(WorkoutCommand)? _onCommandDetected;

  static final Map<String, Map<WorkoutCommand, List<String>>>
      _localizedCommands = {
    'en': {
      WorkoutCommand.start: ['start', 'begin', 'go'],
      WorkoutCommand.stop: ['stop', 'finish', 'end'],
      WorkoutCommand.pause: ['pause', 'wait'],
      WorkoutCommand.resume: ['resume', 'continue'],
      WorkoutCommand.next: ['next', 'skip'],
      WorkoutCommand.previous: ['previous', 'back'],
    },
    'es': {
      WorkoutCommand.start: ['empezar', 'inicio', 'vamos'],
      WorkoutCommand.stop: ['parar', 'terminar', 'finalizar'],
      WorkoutCommand.pause: ['pausa', 'espera'],
      WorkoutCommand.resume: ['continuar', 'reanudar'],
      WorkoutCommand.next: ['siguiente', 'saltar'],
      WorkoutCommand.previous: ['anterior', 'atrás'],
    },
    'de': {
      WorkoutCommand.start: ['start', 'beginnen', 'los'],
      WorkoutCommand.stop: ['stopp', 'fertig', 'beenden'],
      WorkoutCommand.pause: ['pause', 'warten'],
      WorkoutCommand.resume: ['weiter', 'fortfahren'],
      WorkoutCommand.next: ['nächste', 'überspringen'],
      WorkoutCommand.previous: ['zurück', 'vorherige'],
    },
  };

  Future<bool> initialize({String locale = 'en-US'}) async {
    _locale = locale;
    if (_isAvailable) {
      return true;
    }

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
      return false;
    }
  }

  Future<void> startListening(Function(WorkoutCommand) onCommand) async {
    if (!_isAvailable) {
      bool success = await initialize(locale: _locale);
      if (!success) {
        return;
      }
    }

    if (_isListening) {
      return;
    }

    _onCommandDetected = onCommand;
    _isListening = true;

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: _locale,
      listenFor: const Duration(hours: 1),
      pauseFor: const Duration(seconds: 5),
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    _onCommandDetected = null;
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!result.finalResult) {
      return;
    }

    final text = result.recognizedWords.toLowerCase();
    debugPrint('Detected speech: $text');

    final langCode = _locale.split('-')[0];
    final commands = _localizedCommands[langCode] ?? _localizedCommands['en']!;

    WorkoutCommand detected = WorkoutCommand.unknown;

    for (final entry in commands.entries) {
      if (entry.value.any((word) => text.contains(word))) {
        detected = entry.key;
        break;
      }
    }

    if (detected != WorkoutCommand.unknown && _onCommandDetected != null) {
      _onCommandDetected!(detected);
    }
  }

  bool get isListening => _isListening;

  void setLocale(String locale) {
    _locale = locale;
    if (_isListening) {
      // Re-start listening with new locale
      stopListening().then((_) {
        if (_onCommandDetected != null) {
          startListening(_onCommandDetected!);
        }
      });
    }
  }
}
