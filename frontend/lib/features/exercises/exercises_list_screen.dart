import 'package:flutter/material.dart';
import '../../core/constants/exercises.dart';
import '../../features/workout/pre_workout_screen.dart';
import 'package:rhockai/l10n/app_localizations.dart';

class ExercisesListScreen extends StatelessWidget {
  const ExercisesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = Exercises.allExercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.exercises ?? 'Exercises'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return _buildExerciseCard(context, exercise);
          },
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseData exercise) {
    return GestureDetector(
      onTap: () {
        // Navigate to PreWorkoutScreen with exercise details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreWorkoutScreen(
              exerciseType: exercise.id, // e.g., 'pushup'
              title: exercise.name,
              description: exercise.description,
              imageUrl: _getImageUrl(exercise.id),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Placeholder
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  _getImageUrl(exercise.id),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.fitness_center,
                        size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exercise.muscleGroups
                              .take(2)
                              .join(', ')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(exercise.difficulty)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exercise.difficulty.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getDifficultyColor(exercise.difficulty),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(String id) {
    // Mock images from Unsplash based on exercise type
    switch (id) {
      case 'pushup':
        return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80';
      case 'squat':
        return 'https://images.unsplash.com/photo-1574680096141-1cddd32e04ca?auto=format&fit=crop&q=80'; // Squat image
      case 'plank':
        return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80'; // Plank/Abs image
      default:
        return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
