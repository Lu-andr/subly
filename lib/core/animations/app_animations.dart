import 'package:flutter/material.dart';

abstract final class AppAnimations {
  static const fast = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 480);
  static const stagger = Duration(milliseconds: 70);
  static const curve = Curves.easeOutCubic;
  static bool reduceMotion = false;
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.reduceMotion || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      duration: AppAnimations.standard + delay,
      curve: AppAnimations.curve,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    required this.value,
    required this.style,
    this.prefix = '₽',
    super.key,
  });
  final double value;
  final TextStyle style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.reduceMotion || MediaQuery.disableAnimationsOf(context)) {
      return Text(_formatAmount(value, prefix), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: AppAnimations.slow,
      curve: AppAnimations.curve,
      builder: (_, amount, _) =>
          Text(_formatAmount(amount, prefix), style: style),
    );
  }
}

String _formatAmount(double value, String prefix) {
  if (!value.isFinite) return 'Слишком большое число';
  if (value.abs() >= 1000000000000) {
    return '$prefix${value.toStringAsExponential(2)}';
  }
  return '$prefix${value.toStringAsFixed(2)}';
}
