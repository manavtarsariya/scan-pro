import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../controllers/onboarding_controller.dart';
import '../main_nav_screen.dart';

/// Subscription & Paywall Screen for ScanPro.
/// Features Weekly, Monthly, and Yearly (Pre-selected, Best Value, 3-Day Trial).
class PaywallScreen extends StatefulWidget {
  final bool isFromOnboarding;

  const PaywallScreen({
    super.key,
    this.isFromOnboarding = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // 0: Weekly, 1: Monthly, 2: Yearly (Yearly pre-selected by default)
  int _selectedPlanIndex = 2;

  final List<PaywallPlan> _plans = const [
    PaywallPlan(
      id: 'weekly',
      title: 'Weekly',
      price: '₹79',
      period: '/ week',
      subtitle: 'Billed weekly',
      isPopular: false,
    ),
    PaywallPlan(
      id: 'monthly',
      title: 'Monthly',
      price: '₹249',
      period: '/ month',
      subtitle: 'Billed monthly',
      isPopular: false,
    ),
    PaywallPlan(
      id: 'yearly',
      title: 'Yearly',
      price: '₹999',
      period: '/ year',
      subtitle: '₹83 / month • Includes 3-Day Free Trial',
      badge: 'BEST VALUE - SAVE 65%',
      isPopular: true,
      hasTrial: true,
    ),
  ];

  Future<void> _handleDismiss() async {
    if (widget.isFromOnboarding) {
      await OnboardingController.completeOnboarding();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleSubscribe() {
    final selectedPlan = _plans[_selectedPlanIndex];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedPlan.hasTrial
              ? 'Starting 3-Day Free Trial (RevenueCat Step 7)'
              : 'Subscribing to ${selectedPlan.title} (RevenueCat Step 7)',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _handleDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlan = _plans[_selectedPlanIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Close Button & Restore
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMd,
                vertical: AppDimensions.spaceSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _handleDismiss,
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Restoring purchases... (Step 7)'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text(
                      'Restore',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: AppDimensions.screenPadding,
                child: Column(
                  children: [
                    // Gold Crown / Pro Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),

                    // Title
                    Text(
                      'ScanPro Unlimited',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXs),
                    const Text(
                      'Unlock all tools, AI assistant & export with zero limits.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceLg),

                    // Feature List Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppDimensions.roundedCard,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow('Unlimited Multi-Page Document Scans'),
                          _buildDivider(),
                          _buildFeatureRow('No Watermarks & 100% Ad-Free'),
                          _buildDivider(),
                          _buildFeatureRow('AI Tools (OCR, Summarize, Chat with PDF)'),
                          _buildDivider(),
                          _buildFeatureRow('PDF Toolkit (Merge, Split, Compress, Lock)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceLg),

                    // Plan Selection Cards
                    Column(
                      children: List.generate(_plans.length, (index) {
                        final plan = _plans[index];
                        final isSelected = _selectedPlanIndex == index;
                        return _buildPlanCard(plan, isSelected, index);
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA Area
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceLg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightCta,
                    child: ElevatedButton(
                      onPressed: _handleSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                      ),
                      child: Text(
                        selectedPlan.hasTrial
                            ? 'Start 3-Day Free Trial'
                            : 'Continue with ${selectedPlan.title}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cancel anytime in Google Play Subscriptions • Secured via RevenueCat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.primarySoftTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildPlanCard(PaywallPlan plan, bool isSelected, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPlanIndex = index;
          });
        },
        borderRadius: AppDimensions.roundedCard,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoftTint : AppColors.surface,
            borderRadius: AppDimensions.roundedCard,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    width: isSelected ? 6 : 2,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (plan.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppColors.premiumGradient,
                              borderRadius: AppDimensions.roundedFull,
                            ),
                            child: Text(
                              plan.badge!,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    plan.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    plan.period,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaywallPlan {
  final String id;
  final String title;
  final String price;
  final String period;
  final String subtitle;
  final String? badge;
  final bool isPopular;
  final bool hasTrial;

  const PaywallPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.subtitle,
    this.badge,
    this.isPopular = false,
    this.hasTrial = false,
  });
}
