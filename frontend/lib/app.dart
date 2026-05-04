import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rhockai/l10n/app_localizations.dart';
import 'core/config/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/adaptive_dashboard.dart';
import 'features/dashboard/workout_history.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/camera_ai/camera_ai_screen.dart';
import 'features/analytics/providers/analytics_provider.dart';
import 'features/analytics/providers/analytics_observer.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'core/providers/settings_provider.dart';
import 'features/payments/premium_upgrade_screen.dart';
import 'features/payments/payment_service.dart';
import 'core/services/update_service.dart';

class AIWorkoutTrackerApp extends ConsumerStatefulWidget {
  const AIWorkoutTrackerApp({super.key});

  @override
  ConsumerState<AIWorkoutTrackerApp> createState() =>
      _AIWorkoutTrackerAppState();
}

class _AIWorkoutTrackerAppState extends ConsumerState<AIWorkoutTrackerApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Safety timeout: ensure we proceed even if network calls hang
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    try {
      await _checkAuth();
      await _initAnalytics();
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (e.toString().contains('401')) {
        final authRepo = AuthRepository();
        await authRepo.logout();
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkAuth() async {
    try {
      final authRepo = AuthRepository();
      bool loggedIn = await authRepo.isLoggedIn();

      if (loggedIn) {
        try {
          // Verify token by getting current user
          await authRepo.getCurrentUser();
        } catch (e) {
          debugPrint('Token verification failed: $e');
          if (e.toString().contains('401') || e.toString().contains('Session expired')) {
            await authRepo.logout();
            loggedIn = false;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
        });

        if (loggedIn) {
          final token = await authRepo.getToken();
          if (token != null) {
            final paymentService = ref.read(paymentServiceProvider);
            paymentService.connectToNotifications(token, context);
          }
        }
        
        // Check for app updates once we know auth status
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            UpdateService.checkForUpdate(context);
          }
        });
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }
  }

  Future<void> _initAnalytics() async {
    final analytics = ref.read(analyticsServiceProvider);

    String osName = 'unknown';
    String osVersion = 'unknown';
    String deviceType = 'mobile';

    if (!kIsWeb) {
      osName = Platform.operatingSystem;
      osVersion = Platform.operatingSystemVersion;
    } else {
      osName = 'web';
      deviceType = 'browser';
    }

    await analytics.startSession(
      appVersion: '2.0.0', // From pubspec.yaml
      osName: osName,
      osVersion: osVersion,
      deviceType: deviceType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final settings = ref.watch(settingsProvider);

    // Main App with consistent structure
    return MaterialApp(
      title: 'Rhockai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: locale,
      navigatorObservers: [
        AnalyticsObserver(analytics),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _isLoading 
        ? _buildLoadingScreen() 
        : (_isLoggedIn ? const AdaptiveDashboard() : const LoginScreen()),
      onGenerateRoute: (settings) {
        // Handle named routes safely
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const AdaptiveDashboard());
        }
        if (settings.name == '/demo') {
          return MaterialPageRoute(builder: (_) => const CameraAIScreen(exerciseType: 'pushup', isDemo: true));
        }
        if (settings.name == '/camera') {
          final args = settings.arguments as String? ?? 'pushup';
          return MaterialPageRoute(builder: (_) => CameraAIScreen(exerciseType: args));
        }
        if (settings.name == '/history') {
          return MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen());
        }
        if (settings.name == '/progress') {
          return MaterialPageRoute(builder: (_) => const ProgressScreen());
        }
        if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (_) => const SettingsScreen());
        }
        if (settings.name == '/premium') {
          return MaterialPageRoute(builder: (_) => const PremiumUpgradeScreen());
        }
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        return null;
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E27), // Match brand dark background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)), // Neon Blue
            ),
            SizedBox(height: 24),
            Text(
              'RHOCKAI',
              style: TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontFamily: 'Rajdhani',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
