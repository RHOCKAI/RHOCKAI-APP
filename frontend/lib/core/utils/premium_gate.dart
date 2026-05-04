import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/features/auth/presentation/providers/auth_provider.dart';

/// Checks if the current user has premium access (paid OR active trial).
/// Since the backend already computes this and returns is_premium=true
/// during the trial, this simply reads the cached user state.
bool hasPremiumAccess(WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  if (user == null) return false;
  return user['is_premium'] == true;
}

/// Returns true if the user is specifically in a free trial (not yet paid).
bool isInFreeTrial(WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  if (user == null) return false;
  return user['is_trial'] == true;
}

/// Returns the number of days left in the trial, or null if not in trial.
int? trialDaysRemaining(WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  if (user == null || user['trial_ends_at'] == null) return null;
  final trialEnd = DateTime.tryParse(user['trial_ends_at']);
  if (trialEnd == null) return null;
  final diff = trialEnd.difference(DateTime.now()).inDays + 1;
  return diff.clamp(0, 7);
}

/// Navigates to /premium paywall if user does NOT have premium access.
/// Returns true if access was granted, false if redirected.
bool requirePremium(BuildContext context, WidgetRef ref) {
  if (hasPremiumAccess(ref)) return true;
  Navigator.pushNamed(context, '/premium');
  return false;
}
