import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_theme.dart';
import '../../../shared/widgets/pulse_animation.dart';

class MuscleHeatmapCard extends ConsumerWidget {
  const MuscleHeatmapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real implementation, this would read from a provider tracking workout history
    final muscleStrain = {
      'Chest': 0.8, // 80% strained (needs recovery)
      'Legs': 0.2, // 20% strained (fresh)
      'Core': 0.5,
      'Arms': 0.7,
      'Back': 0.1,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.accessibility_new_rounded, color: AppTheme.neonBlue, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'MUSCLE RECOVERY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                ],
              ),
              PulseAnimation(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.neonBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: AppTheme.neonBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...muscleStrain.entries.map((e) => _buildMuscleBar(e.key, e.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildMuscleBar(String name, double strain) {
    // strain > 0.7 = Red (High Strain)
    // strain > 0.4 = Orange/Yellow (Medium)
    // strain <= 0.4 = Green/Blue (Fresh)
    Color barColor = AppTheme.neonBlue;
    if (strain > 0.7) barColor = AppTheme.neonOrange; // Reddish orange
    else if (strain > 0.4) barColor = Colors.amber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Text(
                strain > 0.7 ? 'FATIGUED' : (strain > 0.4 ? 'MODERATE' : 'FRESH'),
                style: TextStyle(color: barColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: strain,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
