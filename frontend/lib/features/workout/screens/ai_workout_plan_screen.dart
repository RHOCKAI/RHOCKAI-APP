import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/core/config/app_theme.dart';
import 'package:rhockai/features/camera_ai/camera_ai_screen.dart';

class AIWorkoutPlanScreen extends ConsumerStatefulWidget {
  const AIWorkoutPlanScreen({super.key});

  @override
  ConsumerState<AIWorkoutPlanScreen> createState() => _AIWorkoutPlanScreenState();
}

class _AIWorkoutPlanScreenState extends ConsumerState<AIWorkoutPlanScreen> {
  // Mock data for the demonstration of the AI Engine
  final String planName = "12-Week Hypertrophy Protocol";
  final int currentDay = 14;
  final String focusArea = "Chest & Triceps";
  
  final List<Map<String, dynamic>> plannedExercises = [
    {
      "name": "Barbell Bench Press",
      "sets": 4,
      "reps": 8,
      "target_weight": 85,
      "ai_note": "Increased from 80kg based on 94% form accuracy last week.",
      "is_substituted": false,
      "icon": Icons.fitness_center_rounded
    },
    {
      "name": "Push-Ups",
      "sets": 3,
      "reps": 18,
      "target_weight": null,
      "ai_note": "Reps increased by 10%. Push hard!",
      "is_substituted": false,
      "icon": Icons.accessibility_new_rounded
    },
    {
      "name": "Dumbbell Flyes",
      "sets": 3,
      "reps": 12,
      "target_weight": 15,
      "ai_note": "Focus on slow eccentric movement.",
      "is_substituted": true,
      "original_exercise": "Cable Crossovers",
      "icon": Icons.sports_gymnastics_rounded
    }
  ];

  void _adaptExercise(int index) {
    // In a real app, this would call the backend adapt_exercise_for_equipment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "AI Engine calculating optimal substitute for same muscle group...",
          style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.neonBlue.withOpacity(0.8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('MY AI PLAN', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanHeader(),
            const SizedBox(height: 32),
            _buildAIInsightsCard(),
            const SizedBox(height: 32),
            const Text(
              "TODAY'S WORKOUT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rajdhani',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            ...plannedExercises.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildExerciseCard(entry.value, entry.key),
              );
            }).toList(),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: 64,
        margin: const EdgeInsets.only(bottom: 16),
        child: ElevatedButton(
          onPressed: () {
            // Start the first exercise in the Camera AI
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const CameraAIScreen(exerciseType: 'Push-Ups'))
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonBlue,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: AppTheme.neonBlue.withOpacity(0.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 28),
              SizedBox(width: 12),
              Text(
                'START AI SESSION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        image: DecorationImage(
          image: const NetworkImage('https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&q=80'),
          fit: BoxFit.cover,
          opacity: 0.2,
          colorFilter: ColorFilter.mode(AppTheme.neonBlue.withOpacity(0.3), BlendMode.color),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.neonBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              "DAY $currentDay • ${focusArea.toUpperCase()}",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.neonBlue,
                letterSpacing: 1.5,
                fontFamily: 'Rajdhani',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            planName.toUpperCase(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Rajdhani',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Powered by Dynamic Progressive Overload",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonOrange.withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonOrange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_graph_rounded, color: AppTheme.neonOrange),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI ADJUSTMENT APPLIED",
                  style: TextStyle(
                    color: AppTheme.neonOrange,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontFamily: 'Rajdhani',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Your average accuracy was 92% last week. We've increased the intensity for today's session.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Outfit',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: exercise['is_substituted'] 
            ? AppTheme.neonGreen.withOpacity(0.3) 
            : Colors.white.withOpacity(0.05)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Rajdhani',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${exercise['sets']} SETS × ${exercise['reps']} REPS ${exercise['target_weight'] != null ? '• ${exercise['target_weight']} KG' : ''}",
                        style: const TextStyle(
                          color: AppTheme.neonBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _adaptExercise(index),
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white54),
                  tooltip: "Adapt Equipment",
                ),
              ],
            ),
          ),
          
          // AI Notes Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: exercise['is_substituted'] 
                ? AppTheme.neonGreen.withOpacity(0.05)
                : Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  exercise['is_substituted'] ? Icons.check_circle_outline_rounded : Icons.psychology_rounded,
                  color: exercise['is_substituted'] ? AppTheme.neonGreen : Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise['is_substituted'] 
                      ? "Adapted from ${exercise['original_exercise']}"
                      : exercise['ai_note'],
                    style: TextStyle(
                      color: exercise['is_substituted'] ? AppTheme.neonGreen : Colors.white54,
                      fontSize: 12,
                      fontFamily: 'Outfit',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
