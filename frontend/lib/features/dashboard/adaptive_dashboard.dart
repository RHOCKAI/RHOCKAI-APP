import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_professional.dart';

/// Adaptive dashboard that shows ProfessionalDashboard on all platforms
/// The ProfessionalDashboard is responsive and works well on mobile, tablet, and desktop
class AdaptiveDashboard extends ConsumerWidget {
  const AdaptiveDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always show ProfessionalDashboard - it's responsive for all screen sizes
    return const ProfessionalDashboard();
  }
}
