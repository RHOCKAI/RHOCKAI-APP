import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Fallback if .env is missing (useful for first run)
    debugPrint('Warning: .env file not found. Using defaults.');
  }

  runApp(
    const ProviderScope(
      child: AIWorkoutTrackerApp(),
    ),
  );
}
