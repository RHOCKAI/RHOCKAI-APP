import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/features/payments/payment_service.dart';
import 'package:rhockai/features/auth/presentation/providers/auth_provider.dart';
import 'package:rhockai/features/analytics/providers/analytics_provider.dart';
import 'package:rhockai/l10n/app_localizations.dart';

class PremiumUpgradeScreen extends ConsumerStatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  ConsumerState<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends ConsumerState<PremiumUpgradeScreen> with SingleTickerProviderStateMixin {
  String _selectedPlan = 'yearly';
  bool _showCloseButton = false;
  Timer? _closeButtonTimer;

  @override
  void initState() {
    super.initState();
    
    // Track paywall viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackFeature('paywall', 'viewed');
      _setupNotifications();
    });

    // 3 second delay for close button
    _closeButtonTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCloseButton = true;
        });
      }
    });
  }

  Future<void> _setupNotifications() async {
    final authRepo = ref.read(authRepositoryProvider);
    final token = await authRepo.getToken();
    
    if (token != null && mounted) {
      ref.read(paymentServiceProvider).connectToNotifications(token, context);
    }
  }

  @override
  void dispose() {
    _closeButtonTimer?.cancel();
    super.dispose();
  }

  void _handleSelectPlan(String planId) {
    setState(() {
      _selectedPlan = planId;
    });
    ref.read(analyticsServiceProvider).trackFeature('paywall', 'plan_selected', extraData: {'plan': planId});
  }

  void _handleSubscribe() async {
    final service = ref.read(paymentServiceProvider);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await service.purchasePlan(_selectedPlan);
      
      if (context.mounted) {
        Navigator.pop(context); // close dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    }
  }

  void _handleRestore() async {
    final service = ref.read(paymentServiceProvider);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await service.getCustomerPortal();
      
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Portal error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final bool isPremium = user != null && user['is_premium'] == true;

    if (isPremium) {
      return _buildPremiumActiveView(context);
    }

    final l10n = AppLocalizations.of(context)!;
    
    // Check if new keys exist in l10n, otherwise fallback to english
    // Since we generate the arb files, we can just assume they exist.
    // If user's code generation fails, we fallback gracefully here just in case? 
    // Dart's generated l10n class will guarantee the getters exist once generated.

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Very dark modern grey/black
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  const Center(
                    child: Icon(Icons.fitness_center, color: Colors.greenAccent, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.goPremiumTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.goPremiumSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Feature Checklist
                  _buildFeatureRow(l10n.featureHistory),
                  const SizedBox(height: 12),
                  _buildFeatureRow(l10n.featureAccuracy),
                  const SizedBox(height: 12),
                  _buildFeatureRow(l10n.featureHeatmap),
                  const SizedBox(height: 12),
                  _buildFeatureRow(l10n.featureAchievements),
                  const SizedBox(height: 12),
                  _buildFeatureRow(l10n.featureVoice),
                  const SizedBox(height: 12),
                  _buildFeatureRow(l10n.featureSupport),
                  
                  const SizedBox(height: 40),

                  // Plans
                  _buildPlanCard(
                    id: 'weekly',
                    title: l10n.weeklyPlanTitle,
                    price: l10n.weeklyPlanPriceText,
                    label: l10n.weeklyPlanLabel,
                    isFaded: true,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    id: 'monthly',
                    title: l10n.monthlyPlanTitle,
                    price: l10n.monthlyPlanPriceText,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    id: 'yearly',
                    title: l10n.yearlyPlanTitle,
                    price: l10n.yearlyPlanPriceText,
                    badge: l10n.yearlyPlanBadge,
                    isHero: true,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    id: 'lifetime',
                    title: l10n.lifetimePlanTitle,
                    price: l10n.lifetimePlanPriceText,
                    label: l10n.lifetimePlanLabel,
                  ),

                  const SizedBox(height: 32),

                  // CTA
                  ElevatedButton(
                    onPressed: _handleSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.startFreeTrial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Text(l10n.freeTrialBadge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Fine print
                  Text(
                    l10n.cancelAnytime,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Restore
                  Center(
                    child: TextButton(
                      onPressed: _handleRestore,
                      child: Text(l10n.restorePurchases, style: const TextStyle(color: Colors.white54, decoration: TextDecoration.underline)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Close button (Maybe later)
            if (_showCloseButton)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  child: Text(l10n.maybeLater, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    String? badge,
    String? label,
    bool isHero = false,
    bool isFaded = false,
  }) {
    final isSelected = _selectedPlan == id;
    
    return GestureDetector(
      onTap: () => _handleSelectPlan(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isHero ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? (isHero ? Colors.greenAccent : Colors.white) 
                : Colors.white.withOpacity(isFaded ? 0.1 : 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(isFaded ? 0.5 : 0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ]
                  ],
                ),
                Text(
                  price,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(isFaded ? 0.5 : 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -26,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActiveView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionStatus),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              l10n.premiumMemberStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.premiumMemberDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _handleRestore,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: Text(l10n.manageSubscription, style: const TextStyle(fontSize: 18, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
