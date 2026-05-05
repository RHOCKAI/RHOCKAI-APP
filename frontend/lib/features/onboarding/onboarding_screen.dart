import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/features/auth/data/repositories/auth_repository.dart';
import 'package:rhockai/features/auth/presentation/providers/auth_provider.dart';

/// 🎯 Psychologically designed onboarding flow
/// Uses goal-setting, identity-based framing, and commitment psychology
/// to maximize user engagement and conversion.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Answers
  String? _selectedGoal;
  String? _selectedLevel;
  String? _selectedDaysPerWeek;
  String? _selectedTimePerSession;
  final List<String> _selectedInterests = [];

  late AnimationController _fadeController;

  final AuthRepository _authRepo = AuthRepository();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        _fadeController.forward();
      });
    } else {
      _completeOnboarding();
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0: return _selectedGoal != null;
      case 1: return _selectedLevel != null;
      case 2: return _selectedDaysPerWeek != null;
      case 3: return _selectedTimePerSession != null;
      case 4: return _selectedInterests.isNotEmpty;
      default: return false;
    }
  }

  Future<void> _completeOnboarding() async {
    // Map level to fitness_level for API
    String? fitnessLevel;
    switch (_selectedLevel) {
      case 'Just starting out':
        fitnessLevel = 'beginner';
        break;
      case 'Some experience':
        fitnessLevel = 'beginner';
        break;
      case 'Intermediate':
        fitnessLevel = 'intermediate';
        break;
      case 'Advanced athlete':
        fitnessLevel = 'advanced';
        break;
    }

    try {
      // Save profile data to backend
      await _authRepo.updateProfile(fitnessLevel: fitnessLevel);
      // Refresh current user in provider
      final user = await _authRepo.getCurrentUser();
      if (mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        await Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (_) {
      if (mounted) {
        await Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(),
            const SizedBox(height: 20),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGoalPage(),
                  _buildLevelPage(),
                  _buildDaysPage(),
                  _buildTimePage(),
                  _buildInterestsPage(),
                ],
              ),
            ),

            // CTA Button
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: () {
                setState(() => _currentStep--);
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );
              },
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white24, size: 18),
            )
          else
            const SizedBox(width: 18),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 5,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonBlue),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_currentStep + 1}/5',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'Rajdhani',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return _buildPage(
      image: 'assets/app_icon/login.png',
      headline: "What's your\nmain goal?",
      subtext: "We'll build your perfect plan around this.",
      child: Column(
        children: [
          _buildOptionCard(
            icon: '🔥',
            title: 'Lose Weight',
            subtitle: 'Burn fat and get lean',
            value: 'Lose Weight',
            selected: _selectedGoal,
            onTap: (v) => setState(() => _selectedGoal = v),
          ),
          _buildOptionCard(
            icon: '💪',
            title: 'Build Strength',
            subtitle: 'Get stronger every week',
            value: 'Build Strength',
            selected: _selectedGoal,
            onTap: (v) => setState(() => _selectedGoal = v),
          ),
          _buildOptionCard(
            icon: '🧘',
            title: 'Fix My Posture',
            subtitle: 'Correct imbalances with AI',
            value: 'Fix My Posture',
            selected: _selectedGoal,
            onTap: (v) => setState(() => _selectedGoal = v),
          ),
          _buildOptionCard(
            icon: '⚡',
            title: 'Stay Active & Healthy',
            subtitle: 'Build a consistent habit',
            value: 'Stay Active',
            selected: _selectedGoal,
            onTap: (v) => setState(() => _selectedGoal = v),
          ),
          _buildOptionCard(
            icon: '🤸',
            title: 'Increase Flexibility',
            subtitle: 'Move better, feel better',
            value: 'Increase Flexibility',
            selected: _selectedGoal,
            onTap: (v) => setState(() => _selectedGoal = v),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelPage() {
    return _buildPage(
      emoji: '📊',
      headline: 'What\'s your\nfitness level?',
      subtext: 'Honest answer = better results.',
      child: Column(
        children: [
          _buildOptionCard(
            icon: '🌱',
            title: 'Just Starting Out',
            subtitle: 'New to regular exercise',
            value: 'Just starting out',
            selected: _selectedLevel,
            onTap: (v) => setState(() => _selectedLevel = v),
          ),
          _buildOptionCard(
            icon: '🚶',
            title: 'Some Experience',
            subtitle: 'I workout occasionally',
            value: 'Some experience',
            selected: _selectedLevel,
            onTap: (v) => setState(() => _selectedLevel = v),
          ),
          _buildOptionCard(
            icon: '🏃',
            title: 'Intermediate',
            subtitle: 'I train consistently',
            value: 'Intermediate',
            selected: _selectedLevel,
            onTap: (v) => setState(() => _selectedLevel = v),
          ),
          _buildOptionCard(
            icon: '🏆',
            title: 'Advanced Athlete',
            subtitle: 'I train 5+ days a week',
            value: 'Advanced athlete',
            selected: _selectedLevel,
            onTap: (v) => setState(() => _selectedLevel = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysPage() {
    return _buildPage(
      emoji: '📅',
      headline: 'How many days\ncan you train?',
      subtext: 'Even 2 days a week produces real results.',
      child: Column(
        children: [
          _buildOptionCard(
            icon: '😊',
            title: '2–3 days a week',
            subtitle: 'Light schedule — great start',
            value: '2-3 days',
            selected: _selectedDaysPerWeek,
            onTap: (v) => setState(() => _selectedDaysPerWeek = v),
          ),
          _buildOptionCard(
            icon: '💪',
            title: '4–5 days a week',
            subtitle: 'Serious commitment',
            value: '4-5 days',
            selected: _selectedDaysPerWeek,
            onTap: (v) => setState(() => _selectedDaysPerWeek = v),
          ),
          _buildOptionCard(
            icon: '🔥',
            title: 'Every day',
            subtitle: 'Maximum progress mode',
            value: 'Every day',
            selected: _selectedDaysPerWeek,
            onTap: (v) => setState(() => _selectedDaysPerWeek = v),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePage() {
    return _buildPage(
      emoji: '⏱️',
      headline: 'How long per\nsession?',
      subtext: 'We optimise workouts to fit your schedule.',
      child: Column(
        children: [
          _buildOptionCard(
            icon: '⚡',
            title: '15 minutes',
            subtitle: 'Quick but effective',
            value: '15 min',
            selected: _selectedTimePerSession,
            onTap: (v) => setState(() => _selectedTimePerSession = v),
          ),
          _buildOptionCard(
            icon: '🎯',
            title: '30 minutes',
            subtitle: 'The sweet spot',
            value: '30 min',
            selected: _selectedTimePerSession,
            onTap: (v) => setState(() => _selectedTimePerSession = v),
          ),
          _buildOptionCard(
            icon: '🏋️',
            title: '45+ minutes',
            subtitle: 'Full deep training',
            value: '45+ min',
            selected: _selectedTimePerSession,
            onTap: (v) => setState(() => _selectedTimePerSession = v),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    final options = [
      {'icon': '🤲', 'label': 'Push-Ups'},
      {'icon': '🦵', 'label': 'Squats'},
      {'icon': '🧱', 'label': 'Planks'},
      {'icon': '🫀', 'label': 'Cardio'},
      {'icon': '🧘', 'label': 'Yoga / Stretching'},
      {'icon': '💃', 'label': 'HIIT'},
      {'icon': '🏃', 'label': 'Running'},
      {'icon': '🦾', 'label': 'Core Training'},
    ];

    return _buildPage(
      emoji: '🏡',
      headline: 'PICK YOUR\nINTERESTS',
      subtext: 'We\'ll tailor your sessions to what you love.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: options.map((option) {
          final label = option['label']!;
          final icon = option['icon']!;
          final isSelected = _selectedInterests.contains(label);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedInterests.remove(label);
                } else {
                  _selectedInterests.add(label);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.neonBlue.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.neonBlue
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPage({
    String? emoji,
    String? image,
    required String headline,
    required String subtext,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (emoji != null) Text(emoji, style: const TextStyle(fontSize: 48)),
          if (image != null)
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(image, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              fontFamily: 'Rajdhani',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtext,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 15,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String icon,
    required String title,
    required String subtitle,
    required String value,
    required String? selected,
    required void Function(String) onTap,
  }) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.neonBlue.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.neonBlue
                : Colors.white.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.neonBlue.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.neonBlue, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentStep == 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: AnimatedOpacity(
        opacity: _canProceed ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _canProceed ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonBlue,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              isLast ? 'GET STARTED →' : 'CONTINUE →',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 15,
                fontFamily: 'Rajdhani',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
