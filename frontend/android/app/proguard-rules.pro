# Flutter-specific ProGuard rules

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.runtime.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# FFmpeg Kit
-keep class com.arthenica.ffmpegkit.** { *; }

# SQLCipher / SQLite (if used)
-keep class net.sqlcipher.** { *; }
-keep class org.sqlite.** { *; }

# Keep models/dtos if they are obfuscated and used with Reflection/JSON
-keep class com.example.ai_workout_tracker.models.** { *; }
