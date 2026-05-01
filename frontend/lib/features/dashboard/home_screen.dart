import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/features/camera_ai/session/session_provider.dart';
import 'package:rhockai/features/camera_ai/camera_ai_screen.dart';
import 'package:rhockai/features/auth/data/repositories/auth_repository.dart';
import 'package:rhockai/features/dashboard/workout_history.dart';
import 'package:rhockai/features/progress/progress_screen.dart';
import 'package:rhockai/features/settings/settings_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:rhockai/features/camera_ai/screens/video_analysis_screen.dart';
import 'package:rhockai/features/camera_ai/widgets/exercise_selector_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const WorkoutHistoryScreen(),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Dashboard tab content
class _DashboardTab extends ConsumerStatefulWidget {
  const _DashboardTab();

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab> {
  final _authRepo = AuthRepository();
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authRepo.getCurrentUser();
      setState(() => _userProfile = profile);
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  Future<void> _logout() async {
    await _authRepo.logout();
    if (!mounted) {
      return;
    }
    unawaited(Navigator.pushReplacementNamed(context, '/'));
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(totalStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rhockai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserProfile();
          ref.invalidate(totalStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          _userProfile?['full_name']
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              _userProfile?['full_name'] ?? 'User',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats section
              Text(
                'Your Stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Sessions',
                            '${stats['total_sessions']}',
                            Icons.fitness_center,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Reps',
                            '${stats['total_reps']}',
                            Icons.repeat,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Calories',
                            '${stats['total_calories']}',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Accuracy',
                            '${stats['avg_accuracy'].toStringAsFixed(1)}%',
                            Icons.check_circle,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading stats: $error'),
                ),
              ),
              const SizedBox(height: 24),

              // Exercises section
              Text(
                'Start Workout',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildExerciseCard(
                    context,
                    'Push-Ups',
                    Icons.fitness_center,
                    Colors.blue,
                    () => _startWorkout('pushup'),
                  ),
                  _buildExerciseCard(
                    context,
                    'Squats',
                    Icons.airline_seat_legroom_normal,
                    Colors.green,
                    () => _startWorkout('squat'),
                  ),
                  _buildExerciseCard(
                    context,
                    'Planks',
                    Icons.accessibility_new,
                    Colors.orange,
                    () => _startWorkout('plank'),
                  ),
                  _buildExerciseCard(
                    context,
                    'History',
                    Icons.history,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkoutHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildExerciseCard(
                    context,
                    'Upload Video',
                    Icons.video_library,
                    Colors.indigo,
                    () => _uploadVideo(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startWorkout(String exerciseType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraAIScreen(exerciseType: exerciseType),
      ),
    );
  }

  Future<void> _uploadVideo() async {
    // 1. Pick video file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    // 2. Show exercise selector
    final exerciseType = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ExerciseSelectorSheet(),
    );

    if (exerciseType == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    // 3. Navigate to analysis screen
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoAnalysisScreen(
          videoFile: File(result.files.single.path!),
          exerciseType: exerciseType,
        ),
      ),
    ));
  }
}
