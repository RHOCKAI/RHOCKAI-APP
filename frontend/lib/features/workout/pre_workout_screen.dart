import 'package:flutter/material.dart';
import 'package:rhockai/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../camera_ai/camera_ai_screen.dart';

class PreWorkoutScreen extends ConsumerStatefulWidget {
  final String exerciseType;
  final String title;
  final String description;
  final String imageUrl;

  const PreWorkoutScreen({
    required this.exerciseType,
    required this.title,
    required this.description,
    required this.imageUrl,
    super.key,
  });

  @override
  ConsumerState<PreWorkoutScreen> createState() => _PreWorkoutScreenState();
}

class _PreWorkoutScreenState extends ConsumerState<PreWorkoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: const Color(0xFF0A0E27),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'Rajdhani',
                      color: Colors.white,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            Container(color: const Color(0xFF34495E)),
                      ),
                      // Gradient Overlay for text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.aboutThisWorkout,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontFamily: 'Rajdhani',
                              color: Color(0xFF00D9FF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.6,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Coach recommendations removed (Cleanup)

                          const SizedBox(
                              height: 100), // Space for bottom button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom Button
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraAIScreen(
                          exerciseType: widget.exerciseType,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88), // Neon Green for Action
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Colors.black, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.startWorkout,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 2,
                          fontFamily: 'Rajdhani',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
