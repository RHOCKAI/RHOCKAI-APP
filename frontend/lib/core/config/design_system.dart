import 'package:flutter/material.dart';

/// 🎨 Rhockai Intelligence Design System
/// Athletic Futurism: Dark theme with electric accents
class AppDesign {
  // 🎨 COLORS
  static const Color primaryDark = Color(0xFF0A0E27); // Deep space blue
  static const Color surfaceDark = Color(0xFF151B3D); // Card background
  static const Color cardDark = Color(0xFF1E2749); // Elevated cards

  // Electric accents
  static const Color electricBlue = Color(0xFF00D9FF); // Primary accent
  static const Color neonPurple = Color(0xFF9C27FF); // Secondary accent
  static const Color energyGreen = Color(0xFF00FF88); // Success/active
  static const Color warningOrange = Color(0xFFFF6B35); // Warnings
  static const Color errorRed = Color(0xFFFF3B5C); // Errors

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [energyGreen, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0xFF1E2749),
      Color(0xFF151B3D),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D4);
  static const Color textTertiary = Color(0xFF6B7394);

  // 🔤 TYPOGRAPHY
  static const String primaryFont = 'Outfit'; // Modern, athletic
  static const String displayFont = 'Rajdhani'; // Bold, tech-inspired

  // Text Styles
  static const TextStyle h1 = TextStyle(
    fontFamily: displayFont,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: displayFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: displayFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontFamily: displayFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
    color: textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: textSecondary,
  );

  // 📏 SPACING
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // 📐 BORDER RADIUS
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // 🎭 SHADOWS
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: electricBlue.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 0),
    ),
  ];

  // 🎬 ANIMATION DURATIONS
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // 📱 BREAKPOINTS
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
}

/// 🎨 Glassmorphism Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? blur;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 10,
    this.color,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDesign.space20),
      decoration: BoxDecoration(
        color: color ?? AppDesign.cardDark.withValues(alpha: 0.6),
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: boxShadow ?? AppDesign.shadowMedium,
      ),
      child: child,
    );
  }
}

/// 🔘 Primary Button with Gradient
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? AppDesign.primaryGradient
            : const LinearGradient(colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: onPressed != null ? AppDesign.shadowGlow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: AppDesign.space8),
                      ],
                      Text(text, style: AppDesign.button),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// 📊 Stat Card
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppDesign.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesign.space8),
                decoration: BoxDecoration(
                  color:
                      (color ?? AppDesign.electricBlue).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: color ?? AppDesign.electricBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDesign.space12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppDesign.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.space12),
          Text(
            value,
            style: AppDesign.h2.copyWith(
              foreground: Paint()
                ..shader = AppDesign.primaryGradient.createShader(
                  const Rect.fromLTWH(0, 0, 200, 70),
                ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppDesign.space4),
            Text(subtitle!, style: AppDesign.caption),
          ],
        ],
      ),
    );
  }
}

/// 🏋️ Exercise Card
class ExerciseCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const ExerciseCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.color = AppDesign.electricBlue,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDesign.animationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withValues(alpha: 0.2),
                widget.color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDesign.space16),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppDesign.space16),
                Text(
                  widget.title,
                  style: AppDesign.h3,
                ),
                const SizedBox(height: AppDesign.space8),
                Text(
                  widget.description,
                  style: AppDesign.bodySmall,
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'START',
                      style: AppDesign.button.copyWith(color: widget.color),
                    ),
                    const SizedBox(width: AppDesign.space8),
                    Icon(
                      Icons.arrow_forward,
                      color: widget.color,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
