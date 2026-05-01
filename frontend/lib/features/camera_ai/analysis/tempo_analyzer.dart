import 'dart:math';
import '../../../core/constants/exercises.dart';

/// 📊 Tempo Scoring Analysis
/// 
/// Tracks the eccentric (descent), isometric (pause), and concentric (ascent)
/// phases of a rep to provide rhythm-based feedback and scoring.
class TempoAnalyzer {
  final ExerciseTempo idealTempo;
  
  // Timestamps for phase transitions
  DateTime? _startPhaseTime;
  
  // Phase durations for current/last rep
  double _lastEccentric = 0.0;
  double _lastIsometric = 0.0;
  double _lastConcentric = 0.0;
  
  TempoAnalyzer(this.idealTempo);

  /// Record start of a phase (e.g., when starting to go down)
  void recordPhaseStart() {
    _startPhaseTime = DateTime.now();
  }

  /// Complete current phase and return its duration in seconds
  double completePhase() {
    if (_startPhaseTime == null) {
      return 0.0;
    }
    
    final now = DateTime.now();
    final duration = now.difference(_startPhaseTime!).inMilliseconds / 1000.0;
    _startPhaseTime = now; // Setup for next phase
    return duration;
  }

  /// Update durations for a full rep
  void updateRepDurations(double eccentric, double isometric, double concentric) {
    _lastEccentric = eccentric;
    _lastIsometric = isometric;
    _lastConcentric = concentric;
  }

  /// Calculate tempo score (0-100)
  /// 
  /// Penalizes being too fast (most common) or significantly too slow.
  double calculateScore() {
    if (idealTempo.totalDuration == 0) {
      return 100.0; // Isometric only case (e.g. Plank)
    }

    // Calculate error for each phase
    final eccError = _calculatePhaseError(_lastEccentric, idealTempo.eccentric);
    final isoError = _calculatePhaseError(_lastIsometric, idealTempo.isometric);
    final conError = _calculatePhaseError(_lastConcentric, idealTempo.concentric);
    
    // Average error (0.0 = perfect, 1.0+ = very poor)
    final avgError = (eccError + isoError + conError) / 3.0;
    
    // Convert to score (0-100)
    final score = max(0.0, 100.0 - (avgError * 100.0));
    return score;
  }

  double _calculatePhaseError(double actual, double ideal) {
    if (ideal == 0) {
      return 0; // If phase doesn't exist (e.g. isometric 0)
    }
    
    // Being too fast is penalized more heavily in tempo training
    if (actual < ideal) {
       return (ideal - actual) / ideal;
    } else {
       // Being slower is usually better/harder, but still not "ideal tempo"
       return min(1.0, (actual - ideal) / (ideal * 2.0)); 
    }
  }

  /// Get feedback message based on tempo
  String getTempoFeedback() {
    if (_lastEccentric < idealTempo.eccentric * 0.7) {
      return 'Slow down on the way down! 📉';
    }
    if (_lastConcentric < idealTempo.concentric * 0.7) {
      return 'Explode up, but control it! 🚀';
    }
    if (idealTempo.isometric > 0 && _lastIsometric < idealTempo.isometric * 0.5) {
      return 'Hold that pause! ⏸️';
    }
    return 'Great rhythm! 🥁';
  }

  void reset() {
    _startPhaseTime = null;
    _lastEccentric = 0;
    _lastIsometric = 0;
    _lastConcentric = 0;
  }
}
