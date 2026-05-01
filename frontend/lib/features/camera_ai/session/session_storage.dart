import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'session_model.dart';

/// Local storage for workout sessions using SQLite
class SessionStorage {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'workout_sessions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions(
            id TEXT PRIMARY KEY,
            exercise_type TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            total_reps INTEGER DEFAULT 0,
            correct_reps INTEGER DEFAULT 0,
            average_accuracy REAL DEFAULT 0.0,
            calories_burned INTEGER DEFAULT 0,
            duration_seconds INTEGER DEFAULT 0,
            video_url TEXT,
            shared_to_social INTEGER DEFAULT 0,
            reps_data TEXT,
            synced INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Create index for faster queries
        await db.execute('''
          CREATE INDEX idx_sessions_created_at ON sessions(created_at DESC)
        ''');
      },
    );
  }

  /// Save a workout session to local storage
  Future<void> saveSession(WorkoutSession session) async {
    final db = await database;
    await db.insert(
      'sessions',
      {
        'id': session.id,
        'exercise_type': session.exerciseType,
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime?.toIso8601String(),
        'total_reps': session.totalReps,
        'correct_reps': session.correctReps,
        'average_accuracy': session.averageAccuracy,
        'calories_burned': session.caloriesBurned,
        'duration_seconds': session.duration.inSeconds,
        'video_url': session.videoUrl,
        'shared_to_social': session.sharedToSocial ? 1 : 0,
        'reps_data': jsonEncode(session.reps.map((r) => r.toJson()).toList()),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all sessions (for local display)
  Future<List<WorkoutSession>> getAllSessions({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return maps.map((map) => WorkoutSession.fromJson(map)).toList();
  }

  /// Get sessions that haven't been synced to backend
  Future<List<WorkoutSession>> getPendingSessions() async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => WorkoutSession.fromJson(map)).toList();
  }

  /// Mark a session as synced
  Future<void> markAsSynced(String sessionId) async {
    final db = await database;
    await db.update(
      'sessions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Queue session for later sync (alias for saveSession)
  Future<void> queueForSync(WorkoutSession session) async {
    await saveSession(session);
  }

  /// Get session by ID
  Future<WorkoutSession?> getSession(String id) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }
    return WorkoutSession.fromJson(maps.first);
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get sessions by exercise type
  Future<List<WorkoutSession>> getSessionsByExercise(
    String exerciseType, {
    int limit = 20,
  }) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'exercise_type = ?',
      whereArgs: [exerciseType],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return maps.map((map) => WorkoutSession.fromJson(map)).toList();
  }

  /// Get total stats (for dashboard)
  Future<Map<String, dynamic>> getTotalStats() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        SUM(total_reps) as total_reps,
        SUM(calories_burned) as total_calories,
        AVG(average_accuracy) as avg_accuracy,
        SUM(duration_seconds) as total_duration
      FROM sessions
    ''');

    if (result.isEmpty) {
      return {
        'total_sessions': 0,
        'total_reps': 0,
        'total_calories': 0,
        'avg_accuracy': 0.0,
        'total_duration': 0,
      };
    }

    final stats = result.first;
    return {
      'total_sessions': stats['total_sessions'] ?? 0,
      'total_reps': stats['total_reps'] ?? 0,
      'total_calories': stats['total_calories'] ?? 0,
      'avg_accuracy': (stats['avg_accuracy'] as num?)?.toDouble() ?? 0.0,
      'total_duration': stats['total_duration'] ?? 0,
    };
  }

  /// Clear all sessions (for testing/reset)
  Future<void> clearAllSessions() async {
    final db = await database;
    await db.delete('sessions');
  }

  /// Get sync status
  Future<Map<String, int>> getSyncStatus() async {
    final db = await database;

    final synced = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sessions WHERE synced = 1
    ''');

    final pending = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sessions WHERE synced = 0
    ''');

    return {
      'synced': synced.first['count'] as int? ?? 0,
      'pending': pending.first['count'] as int? ?? 0,
    };
  }
}
