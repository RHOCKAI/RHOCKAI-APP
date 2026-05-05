import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;

  HealthService._internal();

  bool _isConfigured = false;
  Health? _health;

  Future<void> initialize() async {
    if (_isConfigured || kIsWeb) return;
    
    try {
      Health().configure();
      _health = Health();
      _isConfigured = true;
    } catch (e) {
      debugPrint('Health Service init failed: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isConfigured || _health == null) return false;

    try {
      final types = [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WORKOUT,
      ];
      
      // Request access
      bool hasPermissions = await _health!.hasPermissions(types) ?? false;
      if (!hasPermissions) {
        hasPermissions = await _health!.requestAuthorization(types);
      }
      return hasPermissions;
    } catch (e) {
      debugPrint('Failed to request health permissions: $e');
      return false;
    }
  }

  Future<void> saveWorkout({
    required String exerciseName,
    required double caloriesBurned,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!_isConfigured || _health == null) return;
    
    try {
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) return;

      // 1. Write Calories
      if (caloriesBurned > 0) {
        await _health!.writeHealthData(
          value: caloriesBurned,
          type: HealthDataType.ACTIVE_ENERGY_BURNED,
          startTime: startTime,
          endTime: endTime,
        );
      }

      // 2. Write Workout Session
      await _health!.writeWorkoutData(
        activityType: HealthWorkoutActivityType.CROSS_TRAINING,
        title: 'Rhockai: $exerciseName',
        start: startTime,
        end: endTime,
        totalEnergyBurned: caloriesBurned.toInt(),
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );

      debugPrint('✅ Successfully saved workout to Apple Health / Google Fit!');
    } catch (e) {
      debugPrint('Failed to save health data: $e');
    }
  }
}
