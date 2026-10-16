import 'package:flutter/material.dart';
import 'package:rhockai/core/config/design_system.dart';

/// ✨ Layout-safe pulse animation.
///
/// Animates an **outer glow** instead of the child's size. This matters:
/// the previous implementation used `ScaleTransition` up to 1.1×, so wrapping
/// any full-bleed child (`width: double.infinity`) painted 10% wider than the
/// viewport and pushed sibling content off-screen on phones.
///
/// A box-shadow pulse reads as the same "alive" energy but contributes
/// **zero layout size**, so it is always safe.
///
/// Scaling is still available via [scale] for widgets with bounded size
/// (e.g. a circular icon button) — but never for full-bleed children.
///
/// Fully respects the platform "remove animations" accessibility setting.
class PulseAnimation extends StatefulWidget {
  final Widget child;

  /// Shape of the glow. Match the child's own radius for a clean edge.
  final BorderRadius? borderRadius;

  /// Glow colour. Defaults to the theme's primary accent.
  final Color? glowColor;

  /// How far the glow spreads, in logical pixels.
  final double glowSpread;

  /// Peak glow opacity at the top of the pulse.
  final double glowOpacity;

  /// Optional scale pop. **Only use on bounded-size widgets.**
  /// Leave at 1.0 for full-bleed children.
  final double scale;

  final Duration duration;
  final bool active;

  const PulseAnimation({
    super.key,
    required this.child,
    this.borderRadius,
    this.glowColor,
    this.glowSpread = 12,
    this.glowOpacity = 0.32,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 1600),
    this.active = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    _syncAnimation();
  }

  /// Respects the OS-level "Reduce motion" accessibility setting.
  bool _animationsEnabled(BuildContext context) =>
      widget.active && !context.reduceMotion;

  void _syncAnimation() {
    if (_animationsEnabled(context)) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            boxShadow: _animationsEnabled(context)
                ? [
                    BoxShadow(
                      color: glow.withValues(alpha: widget.glowOpacity * t),
                      blurRadius: widget.glowSpread * (0.6 + 0.6 * t),
                      spreadRadius: widget.glowSpread * 0.10 * t,
                    ),
                  ]
                : null,
          ),
          // Scale is opt-in and only ever applied to bounded children.
          child: widget.scale == 1.0
              ? child
              : Transform.scale(
                  scale: widget.scale * (0.97 + 0.03 * t),
                  child: child,
                ),
        );
      },
      child: widget.child,
    );
  }
}