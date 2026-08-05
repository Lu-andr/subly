import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/models/subscription.dart';
import '../animations/app_animations.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      ?action,
    ],
  );
}

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool down = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: down ? .97 : 1,
    duration: AppAnimations.fast,
    child: FilledButton.icon(
      onPressed: widget.onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            },
      icon: widget.icon == null ? const SizedBox.shrink() : Icon(widget.icon),
      label: Text(widget.label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      onHover: (value) => setState(() => down = value),
    ),
  );
}

class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({
    required this.subscription,
    required this.onTap,
    super.key,
  });
  final Subscription subscription;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final days = subscription.nextPayment
        .difference(DateTime.now())
        .inDays
        .clamp(0, 999);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Row(
          children: [
            ServiceIcon(subscription: subscription, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('dd.MM').format(subscription.nextPayment)} · через $days дн.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₽${subscription.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subscription.status == SubscriptionStatus.active
                      ? 'Активна'
                      : 'Приостановлена',
                  style: TextStyle(
                    color: subscription.status == SubscriptionStatus.active
                        ? SublyColors.green
                        : SublyColors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class ServiceIcon extends StatelessWidget {
  const ServiceIcon({required this.subscription, this.size = 48, super.key});
  final Subscription subscription;
  final double size;
  @override
  Widget build(BuildContext context) {
    final name = subscription.name.toLowerCase();
    final (Color background, Widget mark) = switch (name) {
      final value when value.contains('netflix') => (
        const Color(0xFF090909),
        Text(
          'N',
          style: TextStyle(
            color: const Color(0xFFE50914),
            fontSize: size * .52,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      final value when value.contains('spotify') => (
        const Color(0xFF1ED760),
        Icon(Icons.graphic_eq_rounded, color: Colors.black, size: size * .58),
      ),
      final value when value.contains('icloud') => (
        const Color(0xFFEAF4FF),
        Icon(
          Icons.cloud_rounded,
          color: const Color(0xFF147EFB),
          size: size * .58,
        ),
      ),
      final value when value.contains('youtube') => (
        const Color(0xFFFF0033),
        Icon(Icons.play_arrow_rounded, color: Colors.white, size: size * .62),
      ),
      _ => (
        Color(subscription.colorValue).withValues(alpha: .14),
        Text(
          subscription.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Color(subscription.colorValue),
            fontSize: size * .42,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .31),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: .25),
            blurRadius: size * .22,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: mark,
    );
  }
}

class PageContainer extends StatelessWidget {
  const PageContainer({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: children,
    ),
  );
}
