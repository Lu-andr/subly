import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

enum CalculatorMode { percentage, discount, increase, loan, savings }

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  CalculatorMode mode = CalculatorMode.percentage;
  final a = TextEditingController(text: '1000');
  final b = TextEditingController(text: '15');
  final c = TextEditingController(text: '12');
  final d = TextEditingController(text: '0');
  @override
  void initState() {
    super.initState();
    for (final controller in [a, b, c, d]) {
      controller.addListener(_update);
    }
  }

  void _update() => setState(() {});
  @override
  void dispose() {
    for (final controller in [a, b, c, d]) {
      controller.removeListener(_update);
      controller.dispose();
    }
    super.dispose();
  }

  double get x => double.tryParse(a.text) ?? 0;
  double get y => double.tryParse(b.text) ?? 0;
  double get z => double.tryParse(c.text) ?? 0;
  double get w => double.tryParse(d.text) ?? 0;
  List<(String, double)> get result {
    switch (mode) {
      case CalculatorMode.percentage:
        final amount = x * y / 100;
        return [
          ('${_inputLabel(y)}% от ${_inputLabel(x)}', amount),
          ('После увеличения', x + amount),
          ('После уменьшения', x - amount),
        ];
      case CalculatorMode.discount:
        final saved = x * y / 100;
        return [
          ('Размер скидки', saved),
          ('Итоговая цена', x - saved),
          ('Экономия', saved),
        ];
      case CalculatorMode.increase:
        final increase = x * y / 100;
        return [('Новая сумма', x + increase), ('Размер увеличения', increase)];
      case CalculatorMode.loan:
        final principal = math.max(0, x - w);
        final rate = y / 1200;
        final months = math.max(1, z.round());
        final payment = rate == 0
            ? principal / months
            : principal *
                  rate *
                  math.pow(1 + rate, months) /
                  (math.pow(1 + rate, months) - 1);
        final total = payment * months;
        return [
          ('Платёж в месяц', payment),
          ('Всего выплат', total + w),
          ('Переплата', total - principal),
          ('Всего процентов', total - principal),
        ];
      case CalculatorMode.savings:
        final months = math.max(1, z.round());
        final rate = y / 1200;
        var total = x;
        for (var i = 0; i < months; i++) {
          total = total * (1 + rate) + w;
        }
        final contributed = x + w * months;
        return [
          ('Итоговая сумма', total),
          ('Ваши вложения', contributed),
          ('Начисленные проценты', total - contributed),
        ];
    }
  }

  void _reset() {
    a.text = '';
    b.text = '';
    c.text = '';
    d.text = '';
  }

  @override
  Widget build(BuildContext context) => PageContainer(
    children: [
      Text(
        'Калькулятор',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      Text(
        'Понятные расчёты без лишних формул.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 20),
      _ModeSelector(
        mode: mode,
        onChanged: (value) => setState(() => mode = value),
      ),
      const SizedBox(height: 20),
      AnimatedSwitcher(
        duration: AppAnimations.standard,
        child: AppCard(
          key: ValueKey(mode),
          child: Column(children: _fields()),
        ),
      ),
      const SizedBox(height: 16),
      _resultCard(),
      if (mode == CalculatorMode.savings) ...[
        const SizedBox(height: 16),
        _savingsChart(),
      ],
      if (mode == CalculatorMode.loan)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Расчёт ориентировочный и не является кредитным предложением или финансовой рекомендацией.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _reset,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Сбросить'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
    ],
  );

  Widget _resultCard() => AnimatedSwitcher(
    duration: AppAnimations.standard,
    child: Container(
      key: ValueKey(
        '${mode.name}-${result.map((item) => item.$2.toStringAsFixed(2)).join()}',
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SublyColors.navy, SublyColors.purple],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SublyColors.purple.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: SublyColors.accent),
              SizedBox(width: 12),
              Text(
                'Результат',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...result.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFD0D5DD)),
                  ),
                  const SizedBox(height: 7),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedAmount(
                      value: item.$2,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _savingsChart() => AppCard(
    child: SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: SublyColors.purple,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: SublyColors.purple.withValues(alpha: .12),
              ),
              spots: List.generate(
                8,
                (index) => FlSpot(
                  index.toDouble(),
                  _chartValue(x + (result.first.$2 - x) * index / 7),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  List<Widget> _fields() {
    Widget field(
      TextEditingController controller,
      String label, {
      String? suffix,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          LengthLimitingTextInputFormatter(16),
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          counterText: '',
        ),
      ),
    );
    return switch (mode) {
      CalculatorMode.percentage => [
        field(a, 'Сумма'),
        field(b, 'Процент', suffix: '%'),
      ],
      CalculatorMode.discount => [
        field(a, 'Начальная цена'),
        field(b, 'Скидка', suffix: '%'),
      ],
      CalculatorMode.increase => [
        field(a, 'Начальная сумма'),
        field(b, 'Увеличение', suffix: '%'),
      ],
      CalculatorMode.loan => [
        field(a, 'Сумма кредита'),
        field(b, 'Годовая ставка', suffix: '%'),
        field(c, 'Срок', suffix: 'мес.'),
        field(d, 'Первоначальный взнос'),
      ],
      CalculatorMode.savings => [
        field(a, 'Начальная сумма'),
        field(wController, 'Пополнение в месяц'),
        field(b, 'Годовая ставка', suffix: '%'),
        field(c, 'Срок', suffix: 'мес.'),
      ],
    };
  }

  TextEditingController get wController => d;
}

String _inputLabel(double value) {
  if (!value.isFinite) return '∞';
  if (value.abs() >= 1000000000) return value.toStringAsExponential(2);
  return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
}

double _chartValue(double value) {
  if (!value.isFinite) return 1000000000000;
  return value.clamp(-1000000000000, 1000000000000).toDouble();
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});
  final CalculatorMode mode;
  final ValueChanged<CalculatorMode> onChanged;
  static const labels = {
    CalculatorMode.percentage: 'Процент',
    CalculatorMode.discount: 'Скидка',
    CalculatorMode.increase: 'Рост',
    CalculatorMode.loan: 'Кредит',
    CalculatorMode.savings: 'Накопления',
  };
  static const icons = {
    CalculatorMode.percentage: Icons.percent_rounded,
    CalculatorMode.discount: Icons.local_offer_rounded,
    CalculatorMode.increase: Icons.trending_up_rounded,
    CalculatorMode.loan: Icons.account_balance_rounded,
    CalculatorMode.savings: Icons.savings_rounded,
  };
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: CalculatorMode.values.map((value) {
        final selected = mode == value;
        return Padding(
          padding: const EdgeInsets.only(right: 9),
          child: InkWell(
            onTap: () => onChanged(value),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: AppAnimations.standard,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: selected
                    ? SublyColors.purple
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: SublyColors.purple.withValues(alpha: .24),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icons[value],
                    size: 18,
                    color: selected ? Colors.white : SublyColors.purple,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    labels[value]!,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
