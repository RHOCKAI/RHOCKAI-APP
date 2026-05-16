import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/l10n/app_localizations.dart';

import 'package:rhockai/features/auth/data/repositories/auth_repository.dart';
import 'package:rhockai/features/auth/presentation/providers/auth_provider.dart';
import 'package:rhockai/features/camera_ai/session/session_provider.dart';
import 'package:rhockai/features/gamification/widgets/streak_card.dart';
import 'package:rhockai/features/gamification/widgets/level_progress_card.dart';

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
import 'package:rhockai/features/workout/screens/ai_workout_plan_screen.dart';

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
    if (!mounted) {
      return;
    }
    unawaited(Navigator.pushReplacementNamed(context, '/'));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                        _buildHeroSection(currentUser?['full_name'] ?? 'Champ', isMobile, l10n),
                        
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

  Widget _buildHeroSection(String name, bool isMobile, AppLocalizations? l10n) {
    if (l10n == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: const Color(0xFF141B38),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        image: DecorationImage(
          image: const NetworkImage('https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&q=80'),
          fit: BoxFit.cover,
          opacity: 0.15,
          colorFilter: ColorFilter.mode(AppTheme.neonBlue.withValues(alpha: 0.2), BlendMode.color),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.neonBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              l10n.activeSession,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppTheme.neonBlue,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.helloUser(name.toUpperCase()),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Rajdhani',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.postureScoreHigher(12),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              fontFamily: 'Outfit',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _heroActionButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExercisesListScreen())),
                label: l10n.startWorkout.toUpperCase(),
                icon: Icons.bolt_rounded,
                isPrimary: true,
              ),
              const SizedBox(width: 12),
              _heroActionButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AIWorkoutPlanScreen())),
                label: l10n.aiCircuit,
                icon: Icons.auto_awesome,
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroActionButton({required VoidCallback onPressed, required String label, required IconData icon, required bool isPrimary}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.neonBlue : Colors.white.withValues(alpha: 0.05),
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isPrimary ? BorderSide.none : BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 13,
              fontFamily: 'Rajdhani',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatsRow(bool isMobile) {
    final statsAsync = ref.watch(combinedStatsProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
    return Container(
      width: isMobile ? (MediaQuery.of(context).size.width - 48) / 2 : 280,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Icon(Icons.trending_up_rounded, color: AppTheme.neonGreen.withValues(alpha: 0.5), size: 16),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontFamily: 'Rajdhani',
            ),
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
            SizedBox(height: 24),
            _DailyChallengeWrapper(),
          ],
        );
      }
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: FitnessRatingView(rating: 85, level: 'Advanced')),
          SizedBox(width: 24),
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
            const SizedBox(height: 24),
            const CalendarCard(),
            const SizedBox(height: 24),
            const MuscleHeatmapCard(),
            const SizedBox(height: 24),
            const SquadChallengeCard(),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: LeaderboardView(entries: entries)),
          const SizedBox(width: 24),
          Expanded(
            flex: 2, 
            child: Column(
              children: const [
                CalendarCard(),
                SizedBox(height: 24),
                MuscleHeatmapCard(),
                SizedBox(height: 24),
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
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI FORM ANALYSIS', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 2, 
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real-time posture tracking active',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              if (!isMobile) _buildExerciseTabs(),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 24),
            _buildExerciseTabs(),
          ],
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildCameraPreviewMock()),
              if (!isMobile) ...[
                const SizedBox(width: 40),
                Expanded(child: _buildRepPanel()),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 32),
            _buildRepPanel(),
          ],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.neonBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.neonBlue : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Text(
          label.toUpperCase(), 
          style: TextStyle(
            color: isActive ? AppTheme.neonBlue : Colors.white54, 
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1,
            fontFamily: 'Rajdhani',
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreviewMock() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1599058917233-57c0e621c2c2?auto=format&fit=crop&q=80'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: PulseAnimation(
                active: true,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CameraAIScreen(exerciseType: selectedExercise))),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.neonBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonBlue.withValues(alpha: 0.4),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 40),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: AppTheme.glassDecoration(),
                      child: const Row(
                        children: [
                          Icon(Icons.videocam_rounded, color: AppTheme.neonGreen, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'LIVE TRACKING', 
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1.5,
                              fontFamily: 'Rajdhani',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _uploadVideo,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.file_upload_outlined, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepPanel() {
    return Column(
      children: [
        _buildRepTile('CURRENT SESSION', '$currentReps', AppTheme.neonBlue, 'REPS'),
        const SizedBox(height: 16),
        _buildRepTile('FORM ACCURACY', '$postureAccuracy', AppTheme.neonGreen, '%'),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CameraAIScreen(exerciseType: selectedExercise)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonBlue,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center_rounded, size: 20),
                SizedBox(width: 12),
                Text(
                  'START TRAINING', 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 2,
                    fontSize: 14,
                    fontFamily: 'Rajdhani',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepTile(String label, String value, Color color, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: const TextStyle(
              color: Colors.white38, 
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.2,
              fontFamily: 'Rajdhani',
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value, 
                style: TextStyle(
                  color: color, 
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  fontFamily: 'Rajdhani',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit, 
                style: TextStyle(
                  color: color.withValues(alpha: 0.5), 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  fontFamily: 'Rajdhani',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Map<String, dynamic>? user) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 48),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarItem(Icons.grid_view_rounded, 'DASHBOARD', true),
                _buildSidebarItem(Icons.fitness_center_rounded, 'EXERCISES', false, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ExercisesListScreen()));
                }),
                _buildSidebarItem(Icons.auto_graph_rounded, 'USER ANALYTICS', false, onTap: () {
                  Navigator.pushNamed(context, '/progress');
                }),
                _buildSidebarItem(Icons.settings_outlined, 'SETTINGS', false, onTap: () {
                  Navigator.pushNamed(context, '/settings');
                }),
              ],
            ),
          ),
          if (user == null || user['is_premium'] != true) ...[
            _buildPremiumBanner(),
            const SizedBox(height: 24),
          ],
          _buildSidebarItem(Icons.logout_rounded, 'LOGOUT', false, onTap: _logout),
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
    final emoji = user?['profile_emoji'];
    final picUrl = user?['profile_picture'];
    final name = user?['full_name'] ?? 'Champ';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    Widget avatarContent;
    if (picUrl != null && picUrl.toString().isNotEmpty) {
      avatarContent = CircleAvatar(
        radius: 37,
        backgroundImage: NetworkImage(picUrl),
      );
    } else if (emoji != null && emoji.toString().isNotEmpty) {
      avatarContent = Text(emoji, style: const TextStyle(fontSize: 40));
    } else {
      avatarContent = Text(initial, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold));
    }

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.neonBlue, AppTheme.neonPurple],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E2749),
              shape: BoxShape.circle,
            ),
            child: Center(child: avatarContent),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            fontFamily: 'Rajdhani',
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.neonBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'ELITE LEVEL', 
            style: TextStyle(
              color: AppTheme.neonBlue, 
              fontSize: 9, 
              letterSpacing: 2, 
              fontWeight: FontWeight.w900,
              fontFamily: 'Rajdhani',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon, 
          color: isActive ? AppTheme.neonBlue : Colors.white38,
          size: 20,
        ),
        title: Text(
          label, 
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38, 
            fontWeight: FontWeight.w900,
            fontSize: 13,
            fontFamily: 'Rajdhani',
            letterSpacing: 1.5,
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
