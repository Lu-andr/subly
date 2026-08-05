import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});
  final VoidCallback onComplete;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;
  static const pages = [
    (
      Icons.account_balance_wallet_rounded,
      'Вся картина перед глазами',
      'Баланс, расходы и регулярные платежи на одном понятном экране.',
    ),
    (
      Icons.notifications_active_rounded,
      'Ни одного неожиданного списания',
      'Следите за ближайшими платежами и заранее планируйте бюджет.',
    ),
    (
      Icons.calculate_rounded,
      'Считайте уверенно',
      'Пять удобных калькуляторов для процентов, скидок, кредита и накоплений.',
    ),
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: const Text('Пропустить'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: pages.length,
                onPageChanged: (value) => setState(() => index = value),
                itemBuilder: (_, i) {
                  final page = pages[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: SublyColors.purple.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          page.$1,
                          size: 58,
                          color: SublyColors.purple,
                        ),
                      ),
                      const SizedBox(height: 42),
                      Text(
                        page.$2,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.$3,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  width: i == index ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == index
                        ? SublyColors.purple
                        : SublyColors.purple.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              label: index == pages.length - 1 ? 'Начать' : 'Продолжить',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                if (index == pages.length - 1) {
                  widget.onComplete();
                } else {
                  controller.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
