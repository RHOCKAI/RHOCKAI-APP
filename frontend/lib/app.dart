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
    await _checkAuth();
    await _initAnalytics();
  }

  Future<void> _checkAuth() async {
    final authRepo = AuthRepository();
    final loggedIn = await authRepo.isLoggedIn();

    if (loggedIn) {
      final token = await authRepo.getToken();
      if (token != null && mounted) {
        final paymentService = ref.read(paymentServiceProvider);
        paymentService.connectToNotifications(token, context);
      }
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isLoading = false;
      });
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
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final locale = ref.watch(localeProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final settings = ref.watch(settingsProvider);

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
      supportedLocales: const [
        Locale('en'), // English
        Locale('de'), // German
        Locale('ja'), // Japanese
        Locale('fr'), // French
        Locale('es'), // Spanish
        Locale('pt'), // Portuguese
        Locale('ar'), // Arabic
      ],
      initialRoute: _isLoggedIn ? '/home' : '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const AdaptiveDashboard(),
        '/history': (context) => const WorkoutHistoryScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/premium': (context) => const PremiumUpgradeScreen(),
        '/camera': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as String? ?? 'pushup';
          return CameraAIScreen(exerciseType: args);
        },
      },
    );
  }
}
