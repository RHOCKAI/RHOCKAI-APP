import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/l10n/app_localizations.dart';

import 'package:rhockai/features/auth/data/repositories/auth_repository.dart';
import 'package:rhockai/features/auth/presentation/providers/auth_provider.dart';
import 'package:rhockai/features/camera_ai/session/session_provider.dart';
import 'package:rhockai/features/gamification/widgets/streak_card.dart';
import 'package:rhockai/features/gamification/widgets/level_progress_card.dart';
import 'package:rhockai/core/utils/premium_gate.dart';

import 'package:rhockai/shared/widgets/pulse_animation.dart';
import 'package:rhockai/core/config/app_theme.dart';
import 'package:rhockai/features/dashboard/widgets/calendar_card.dart';
import 'package:rhockai/features/dashboard/widgets/muscle_heatmap_card.dart';
import 'package:rhockai/features/gamification/widgets/squad_challenge_card.dart';
import 'package:rhockai/features/camera_ai/camera_ai_screen.dart';
import 'package:rhockai/features/exercises/exercises_list_screen.dart';
import 'package:rhockai/features/gamification/widgets/daily_challenge_card.dart';
import 'package:rhockai/features/gamification/widgets/leaderboard_view.dart';
import 'package:rhockai/features/gamification/widgets/fitness_rating_view.dart';
import 'package:rhockai/features/gamification/data/models/daily_challenge.dart';
import 'package:rhockai/features/gamification/providers/gamification_provider.dart';
import 'package:rhockai/features/workout/screens/daily_circuit_screen.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:rhockai/features/camera_ai/screens/video_analysis_screen.dart';
import 'package:rhockai/features/camera_ai/widgets/exercise_selector_sheet.dart';

/// 🏠 Professional Dashboard - Restored Premium AI Design
class ProfessionalDashboard extends ConsumerStatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  ConsumerState<ProfessionalDashboard> createState() =>
      _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends ConsumerState<ProfessionalDashboard> {
  final AuthRepository _authRepo = AuthRepository();
  String selectedExercise = 'Push-Ups';
  int currentReps = 12;
  int postureAccuracy = 85;

  Future<void> _logout() async {
    await _authRepo.logout();
    if (!mounted) return;
    unawaited(Navigator.pushReplacementNamed(context, '/'));
  }

  Future<void> _uploadVideo() async {
    // 1. Pick video file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    // 2. Show exercise selector
    final exerciseType = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ExerciseSelectorSheet(),
    );

    if (exerciseType == null) return;
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024; // Use 1024 as breakpoint for professional feel

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: isMobile ? _buildDrawer(currentUser) : null,
      body: Row(
        children: [
          // Left Sidebar (hidden on mobile)
          if (!isMobile) _buildSidebar(currentUser),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Mobile/Tablet app bar
                if (isMobile)
                  AppBar(
                    title: Text(AppLocalizations.of(context)?.appTitle ?? 'Rhockai', 
                      style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, letterSpacing: 2)),
                    backgroundColor: theme.colorScheme.surface,
                    elevation: 0,
                  ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WELCOME HERO SECTION
                        _buildHeroSection(currentUser?['full_name'] ?? 'Champ', isMobile),
                        
                        const SizedBox(height: 32),

                        // Top Stats Section
                        _buildTopStatsRow(isMobile),

                        const SizedBox(height: 32),

                        // Gamification Row
                        LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            return const Column(
                              children: [
                                StreakCard(),
                                SizedBox(height: 16),
                                LevelProgressCard(),
                              ],
                            );
                          }
                          return const Row(
                            children: [
                              Expanded(child: StreakCard()),
                              SizedBox(width: 20),
                              Expanded(child: LevelProgressCard()),
                            ],
                          );
                        }),

                        const SizedBox(height: 32),

                        // AI Intelligence Row
                        _buildIntelligenceRow(isMobile),

                        const SizedBox(height: 32),

                        // Leaderboard & Calendar
                        _buildSocialRow(isMobile),

                        const SizedBox(height: 32),

                        // Exercise Controls
                        _buildExerciseControlPanel(theme, isMobile),
                        
                        const SizedBox(height: 48),
                      ],
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

  Widget _buildHeroSection(String name, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00D9FF), Color(0xFF9C27FF)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WELCOME BACK,',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Rajdhani',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to perfect your posture and crush your goals today?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExercisesListScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00D9FF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'QUICK START',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'Rajdhani',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DailyCircuitScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27FF).withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  side: const BorderSide(color: Colors.white24, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI CIRCUIT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'Rajdhani',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatsRow(bool isMobile) {
    final statsAsync = ref.watch(combinedStatsProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return statsAsync.when(
      data: (stats) => Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildStatCard(
            l10n.workoutsToday,
            '${stats['total_sessions'] ?? 0}',
            l10n.sessions,
            Icons.bolt_rounded,
            AppTheme.neonBlue,
            isMobile,
          ),
          _buildStatCard(
            l10n.caloriesBurned,
            '${stats['total_calories'] ?? 0}',
            l10n.kcal,
            Icons.local_fire_department_rounded,
            AppTheme.neonOrange,
            isMobile,
          ),
          _buildStatCard(
            l10n.postureAccuracy,
            '${(stats['average_accuracy'] ?? 0).toInt()}',
            l10n.goodPosture,
            Icons.biotech_rounded,
            AppTheme.neonGreen,
            isMobile,
          ),
        ],
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color, bool isMobile) {
    final theme = Theme.of(context);
    return Container(
      width: isMobile ? (MediaQuery.of(context).size.width - 48) / 2 : 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligenceRow(bool isMobile) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return const Column(
          children: [
            FitnessRatingView(rating: 85, level: 'Advanced'),
            SizedBox(height: 16),
            _DailyChallengeWrapper(),
          ],
        );
      }
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: FitnessRatingView(rating: 85, level: 'Advanced')),
          SizedBox(width: 20),
          Expanded(flex: 3, child: _DailyChallengeWrapper()),
        ],
      );
    });
  }

  Widget _buildSocialRow(bool isMobile) {
    final leaderboardAsync = ref.watch(dailyLeaderboardProvider);
    final entries = leaderboardAsync.valueOrNull ?? [];

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return Column(
          children: [
            LeaderboardView(entries: entries),
            const SizedBox(height: 16),
            const CalendarCard(),
            const SizedBox(height: 16),
            const MuscleHeatmapCard(),
            const SizedBox(height: 16),
            const SquadChallengeCard(),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: LeaderboardView(entries: entries)),
          const SizedBox(width: 20),
          Expanded(
            flex: 2, 
            child: Column(
              children: const [
                CalendarCard(),
                SizedBox(height: 16),
                MuscleHeatmapCard(),
                SizedBox(height: 16),
                SquadChallengeCard(),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildExerciseControlPanel(ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('EXERCISE SELECTION', 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'Rajdhani')),
              const Spacer(),
              _buildExerciseTabs(),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildCameraPreviewMock()),
              const SizedBox(width: 32),
              if (!isMobile) Expanded(child: _buildRepPanel()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTabs() {
    return Row(
      children: [
        _buildTab('Push-Ups', selectedExercise == 'Push-Ups'),
        const SizedBox(width: 12),
        _buildTab('Squats', selectedExercise == 'Squats'),
        const SizedBox(width: 12),
        _buildTab('Planks', selectedExercise == 'Planks'),
      ],
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => selectedExercise = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.neonBlue : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive ? [BoxShadow(color: AppTheme.neonBlue.withValues(alpha: 0.3), blurRadius: 15)] : null,
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.white70, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCameraPreviewMock() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1599058917233-57c0e621c2c2?auto=format&fit=crop&q=80'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: PulseAnimation(
              active: true,
              child: IconButton(
                icon: const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 80),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CameraAIScreen(exerciseType: selectedExercise)));
                },
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.videocam_rounded, color: AppTheme.neonGreen, size: 18),
                      SizedBox(width: 8),
                      Text('CAMERA ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _uploadVideo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.neonBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.neonBlue)),
                    child: const Row(
                      children: [
                        Icon(Icons.video_file, color: AppTheme.neonBlue, size: 18),
                        SizedBox(width: 8),
                        Text('UPLOAD VIDEO', style: TextStyle(color: AppTheme.neonBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
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

  Widget _buildRepPanel() {
    return Column(
      children: [
        _buildRepTile('CURRENT REPS', '$currentReps', AppTheme.neonBlue),
        const SizedBox(height: 16),
        _buildRepTile('ACCURACY', '$postureAccuracy%', AppTheme.neonGreen),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CameraAIScreen(exerciseType: selectedExercise)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('START WORKOUT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildRepTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
        ],
      ),
    );
  }

  Widget _buildSidebar(Map<String, dynamic>? user) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 60),
          _buildSidebarItem(Icons.grid_view_rounded, 'Home', true),
          _buildSidebarItem(Icons.fitness_center_rounded, 'Exercises', false, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ExercisesListScreen()));
          }),
          _buildSidebarItem(Icons.analytics_outlined, 'Progress', false, onTap: () {
            // is_premium from API = true during trial OR paid subscription
            if (user != null && user['is_premium'] == true) {
              Navigator.pushNamed(context, '/progress');
            } else {
              Navigator.pushNamed(context, '/premium');
            }
          }),
          _buildSidebarItem(Icons.settings_outlined, 'Settings', false, onTap: () {
            Navigator.pushNamed(context, '/settings');
          }),
          const Spacer(),
          // Only show premium banner if user has NO access at all (no trial, no paid)
          if (user == null || user['is_premium'] != true) _buildPremiumBanner(),
          const SizedBox(height: 16),
          _buildSidebarItem(Icons.logout_rounded, 'Logout', false, onTap: _logout),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF9C27FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          const Text(
            'GO PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2,
              fontFamily: 'Rajdhani',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unlock all AI features',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'UPGRADE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? user) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.neonBlue, width: 2),
            boxShadow: [BoxShadow(color: AppTheme.neonBlue.withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 50)),
        ),
        const SizedBox(height: 20),
        Text(user?['full_name'] ?? 'Entity-01', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('ELITE LEVEL', style: TextStyle(color: AppTheme.neonBlue, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: isActive ? AppTheme.neonBlue : Colors.white54),
        title: Text(
          label, 
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54, 
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontFamily: 'Rajdhani',
            letterSpacing: 1.2,
          ),
        ),
        tileColor: isActive ? AppTheme.neonBlue.withValues(alpha: 0.1) : Colors.transparent,
      ),
    );
  }

  Widget _buildDrawer(Map<String, dynamic>? user) {
    return Drawer(
      backgroundColor: AppTheme.darkBackground,
      child: _buildSidebar(user),
    );
  }
}

class _DailyChallengeWrapper extends StatelessWidget {
  const _DailyChallengeWrapper();

  @override
  Widget build(BuildContext context) {
    return DailyChallengeCard(
      challenge: DailyChallenge(
        date: DateTime.now().toString(),
        targetReps: 50,
        description: 'Complete 50 push-up reps to maintain elite status.',
        difficultyMultiplier: 1.5,
        targetExercise: 'Push-Ups',
      ),
      onStart: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraAIScreen(exerciseType: 'Push-Ups')));
      },
    );
  }
}
