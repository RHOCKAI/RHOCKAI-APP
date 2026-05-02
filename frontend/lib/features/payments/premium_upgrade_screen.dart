import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhockai/features/payments/payment_service.dart';
import 'package:rhockai/features/auth/presentation/providers/auth_provider.dart';
import 'package:rhockai/l10n/app_localizations.dart';

class PremiumUpgradeScreen extends ConsumerStatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  ConsumerState<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends ConsumerState<PremiumUpgradeScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening for payment notifications as soon as we enter the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications();
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
    // Optional: Only dispose if you want to stop listening when leaving this screen
    // ref.read(paymentServiceProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentService = ref.read(paymentServiceProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final bool isPremium = user != null && user['is_premium'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPremium ? l10n.subscriptionStatus : l10n.upgradeToPremium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              isPremium ? Icons.verified_user : Icons.star, 
              size: 80, 
              color: isPremium ? Colors.green : Colors.amber
            ),
            const SizedBox(height: 24),
            Text(
              isPremium ? l10n.premiumMemberStatus : l10n.unlockFullPotential,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              isPremium 
                ? l10n.premiumMemberDescription 
                : l10n.premiumDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            if (isPremium)
              ElevatedButton(
                onPressed: () => _handlePortal(context, paymentService),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: Text(l10n.manageSubscription, style: const TextStyle(fontSize: 18, color: Colors.white)),
              )
            else ...[
              ElevatedButton(
                onPressed: () => _handleCheckout(context, paymentService, 'monthly'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text(l10n.monthlyPlanPrice, style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _handleCheckout(context, paymentService, 'yearly'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                ),
                child: Text(l10n.yearlyPlanPrice, style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _handleCheckout(context, paymentService, 'lifetime'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.amber[700],
                ),
                child: Text(l10n.lifetimePlanPrice, style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _handlePortal(BuildContext context, PaymentService service) async {
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

  void _handleCheckout(BuildContext context, PaymentService service, String planType) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await service.purchasePlan(planType);
      
      // Close loading indicator
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    }
  }
}
