import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final currentUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final authStateProvider = FutureProvider<bool>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final isLoggedIn = await authRepo.isLoggedIn();
  if (isLoggedIn) {
    try {
      final user = await authRepo.getCurrentUser();
      ref.read(currentUserProvider.notifier).state = user;
    } catch (e) {
      // Token might be invalid
      return false;
    }
  }
  return isLoggedIn;
});
