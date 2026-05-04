import 'package:flutter/material.dart';
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
  late Animation<double> _fadeAnimation;

  final AuthRepository _authRepo = AuthRepository();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
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
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(),

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
      child: Column(
        children: [
          Row(
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
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white54, size: 20),
                )
              else
                const SizedBox(width: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 5,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00D9FF),
                    ),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_currentStep + 1}/5',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return _buildPage(
      emoji: '🎯',
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
      headline: "What's your\nfitness level?",
      subtext: "Honest answer = better results.",
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
      headline: "How many days\ncan you train?",
      subtext: "Even 2 days a week produces real results.",
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
      headline: "How long per\nsession?",
      subtext: "We optimise workouts to fit your schedule.",
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
      emoji: '🏠',
      headline: "Pick your\nfavourite workouts",
      subtext: "All home-based — zero gym equipment needed.",
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
                    ? const Color(0xFF00D9FF).withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00D9FF)
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
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
    required String emoji,
    required String headline,
    required String subtext,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D9FF).withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00D9FF)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D9FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    color: Colors.black, size: 16),
              ),
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
        child: GestureDetector(
          onTap: _canProceed ? _nextStep : null,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: _canProceed
                  ? const LinearGradient(
                      colors: [Color(0xFF00D9FF), Color(0xFF9C27FF)],
                    )
                  : null,
              color: _canProceed ? null : Colors.white12,
              borderRadius: BorderRadius.circular(18),
              boxShadow: _canProceed
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00D9FF).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                isLast ? "LET'S GO →" : 'CONTINUE →',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontFamily: 'Rajdhani',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
