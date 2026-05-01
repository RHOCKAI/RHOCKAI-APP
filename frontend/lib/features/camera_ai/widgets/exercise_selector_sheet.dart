import 'package:flutter/material.dart';

/// Bottom sheet for selecting exercise type
///
/// Matches existing app design patterns from dashboard
class ExerciseSelectorSheet extends StatelessWidget {
  const ExerciseSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Color(0xFF4A90E2)),
              const SizedBox(width: 12),
              Text(
                'Select Exercise Type',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the exercise shown in your video',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7F8C8D),
                ),
          ),
          const SizedBox(height: 24),

          // Exercise options
          _buildExerciseOption(
            context,
            title: 'Push-Ups',
            icon: Icons.fitness_center,
            color: Colors.blue,
            exerciseType: 'pushup',
          ),
          const SizedBox(height: 12),
          _buildExerciseOption(
            context,
            title: 'Squats',
            icon: Icons.airline_seat_legroom_normal,
            color: Colors.green,
            exerciseType: 'squat',
          ),
          const SizedBox(height: 12),
          _buildExerciseOption(
            context,
            title: 'Planks',
            icon: Icons.accessibility_new,
            color: Colors.orange,
            exerciseType: 'plank',
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExerciseOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String exerciseType,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, exerciseType),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Color(0xFF7F8C8D)),
          ],
        ),
      ),
    );
  }
}
