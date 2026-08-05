import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/providers/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.state,
    required this.onViewAll,
    required this.onOpenSubscription,
    super.key,
  });
  final AppState state;
  final VoidCallback onViewAll;
  final ValueChanged<String> onOpenSubscription;

  Future<void> _changeBalance(BuildContext context, bool income) async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              income ? 'Добавить доход' : 'Добавить расход',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(12),
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Сумма',
                prefixText: '₽ ',
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: income ? 'Добавить доход' : 'Добавить расход',
              onPressed: () {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0 && amount <= 999999999) {
                  Navigator.pop(context, income ? amount : -amount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Введите сумму до 999 999 999'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
    if (value != null) {
      state.updateBalance(value);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(income ? 'Доход добавлен' : 'Расход добавлен'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active =
        state.subscriptions
            .where((item) => item.status.name == 'active')
            .toList()
          ..sort((a, b) => a.nextPayment.compareTo(b.nextPayment));
    final monthly = active.fold<double>(
      0,
      (sum, item) => sum + item.monthlyPrice,
    );
    final upcoming = active
        .where(
          (item) => item.nextPayment.difference(DateTime.now()).inDays <= 7,
        )
        .fold<double>(0, (sum, item) => sum + item.price);
    return PageContainer(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateTime.now().hour < 12 ? 'Доброе утро' : 'Добрый день'} 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _russianDate(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SublyColors.navy, SublyColors.purple],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Общий баланс',
                        style: TextStyle(
                          color: Color(0xFFD0D5DD),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => state.updateSettings(
                        state.settings.copyWith(
                          showBalance: !state.settings.showBalance,
                        ),
                      ),
                      icon: Icon(
                        state.settings.showBalance
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: AppAnimations.standard,
                  child: state.settings.showBalance
                      ? AnimatedAmount(
                          key: const ValueKey('amount'),
                          value: state.balance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.3,
                          ),
                        )
                      : const Text(
                          '••••••',
                          key: ValueKey('hidden'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF6CE9A6),
                      size: 18,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '+8,4% за этот месяц',
                      style: TextStyle(
                        color: Color(0xFF6CE9A6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .16),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _changeBalance(context, true),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Доход'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .16),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _changeBalance(context, false),
                        icon: const Icon(Icons.remove_rounded),
                        label: const Text('Расход'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: AppAnimations.stagger,
          child: AppCard(
            child: Column(
              children: [
                const SectionHeader(title: 'Обзор за месяц'),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    _Stat(
                      label: 'Доходы',
                      value: '₽5 420',
                      color: SublyColors.green,
                    ),
                    SizedBox(width: 12),
                    _Stat(
                      label: 'Расходы',
                      value: '₽1 139',
                      color: SublyColors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Stat(
                      label: 'Подписки',
                      value: '₽${monthly.toStringAsFixed(2)}',
                      color: SublyColors.purple,
                    ),
                    const SizedBox(width: 12),
                    const _Stat(
                      label: 'Доступно',
                      value: '₽4 280',
                      color: SublyColors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: SublyColors.purple,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: SublyColors.purple.withValues(alpha: .12),
                          ),
                          spots: const [
                            FlSpot(0, 2),
                            FlSpot(1, 2.8),
                            FlSpot(2, 2.3),
                            FlSpot(3, 4.2),
                            FlSpot(4, 3.7),
                            FlSpot(5, 5.2),
                            FlSpot(6, 4.7),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        SectionHeader(
          title: 'Активные подписки',
          action: TextButton(onPressed: onViewAll, child: const Text('Все')),
        ),
        const SizedBox(height: 12),
        ...active
            .take(3)
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideIn(
                  delay: AppAnimations.stagger * entry.key,
                  child: SubscriptionTile(
                    subscription: entry.value,
                    onTap: () => onOpenSubscription(entry.value.id),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SublyColors.orange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.upcoming_rounded,
                  color: SublyColors.orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ближайшие платежи',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'В течение следующих 7 дней',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '₽${upcoming.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SublyColors.purple.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: SublyColors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'В этом месяце на подписки уйдёт ₽${monthly.toStringAsFixed(2)}.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

String _russianDate(DateTime date) {
  const weekdays = [
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  final weekday = weekdays[date.weekday - 1];
  return '${weekday[0].toUpperCase()}${weekday.substring(1)}, ${date.day} ${months[date.month - 1]}';
}
