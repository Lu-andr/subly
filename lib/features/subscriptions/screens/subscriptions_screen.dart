import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/subscription.dart';
import '../../../data/providers/app_state.dart';

enum SubscriptionFilter { all, active, upcoming, paused }

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({
    required this.state,
    required this.onOpenSubscription,
    super.key,
  });
  final AppState state;
  final ValueChanged<String> onOpenSubscription;
  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  SubscriptionFilter filter = SubscriptionFilter.all;
  String query = '';
  bool yearly = false;

  List<Subscription> get filtered => widget.state.subscriptions.where((item) {
    final matchesQuery = item.name.toLowerCase().contains(query.toLowerCase());
    final matchesFilter = switch (filter) {
      SubscriptionFilter.all => true,
      SubscriptionFilter.active => item.status == SubscriptionStatus.active,
      SubscriptionFilter.paused => item.status == SubscriptionStatus.paused,
      SubscriptionFilter.upcoming =>
        item.status == SubscriptionStatus.active &&
            item.nextPayment.difference(DateTime.now()).inDays <= 7,
    };
    return matchesQuery && matchesFilter;
  }).toList();

  Future<void> _add(BuildContext context) async {
    final value = await showModalBottomSheet<Subscription>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const AddSubscriptionSheet(),
    );
    if (value != null) {
      await widget.state.addSubscription(value);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${value.name}: подписка добавлена')),
        );
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthly = widget.state.subscriptions
        .where((e) => e.status == SubscriptionStatus.active)
        .fold<double>(0, (sum, item) => sum + item.monthlyPrice);
    final next =
        widget.state.subscriptions
            .where((e) => e.status == SubscriptionStatus.active)
            .toList()
          ..sort((a, b) => a.nextPayment.compareTo(b.nextPayment));
    return PageContainer(
      children: [
        Text(
          'Подписки',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Все регулярные платежи под контролем.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        _PeriodSwitch(
          yearly: yearly,
          onChanged: (value) => setState(() => yearly = value),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          child: Container(
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
                Text(
                  yearly ? 'Расходы за год' : 'Расходы за месяц',
                  style: const TextStyle(
                    color: Color(0xFFD0D5DD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedAmount(
                  value: yearly ? monthly * 12 : monthly,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _Summary(
                        label: 'Активных',
                        value:
                            '${widget.state.subscriptions.where((e) => e.status == SubscriptionStatus.active).length}',
                      ),
                    ),
                    Expanded(
                      child: _Summary(
                        label: 'Ближайший',
                        value: next.isEmpty
                            ? '—'
                            : DateFormat(
                                'dd.MM',
                              ).format(next.first.nextPayment),
                      ),
                    ),
                    Expanded(
                      child: _Summary(
                        label: 'За год',
                        value: '₽${(monthly * 12).toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            hintText: 'Найти подписку',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SubscriptionFilter.values
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        const {
                          SubscriptionFilter.all: 'Все',
                          SubscriptionFilter.active: 'Активные',
                          SubscriptionFilter.upcoming: 'Скоро',
                          SubscriptionFilter.paused: 'На паузе',
                        }[value]!,
                      ),
                      selected: filter == value,
                      onSelected: (_) => setState(() => filter = value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: AppAnimations.standard,
          child: filtered.isEmpty
              ? AppCard(
                  key: const ValueKey('empty'),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inbox_rounded,
                        size: 52,
                        color: SublyColors.purple,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Здесь пока пусто',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Выберите другой фильтр или добавьте подписку.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : Column(
                  key: ValueKey('${filter.name}-$query-${filtered.length}'),
                  children: filtered
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FadeSlideIn(
                            delay: AppAnimations.stagger * entry.key,
                            child: SubscriptionTile(
                              subscription: entry.value,
                              onTap: () =>
                                  widget.onOpenSubscription(entry.value.id),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Добавить подписку',
          icon: Icons.add_rounded,
          onPressed: () => _add(context),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFFB8C0D4), fontSize: 12),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ],
  );
}

class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.yearly, required this.onChanged});
  final bool yearly;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .5),
      ),
    ),
    child: Row(
      children: [
        _item(context, false, 'За месяц'),
        _item(context, true, 'За год'),
      ],
    ),
  );
  Widget _item(BuildContext context, bool value, String label) => Expanded(
    child: InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: yearly == value ? SublyColors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: yearly == value
              ? [
                  BoxShadow(
                    color: SublyColors.purple.withValues(alpha: .25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: yearly == value
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({this.initial, super.key});
  final Subscription? initial;
  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController price;
  final note = TextEditingController();
  String category = 'Entertainment';
  BillingPeriod period = BillingPeriod.monthly;
  DateTime payment = DateTime.now().add(const Duration(days: 7));
  bool reminders = true;
  int reminderDays = 3;
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    name = TextEditingController(text: initial?.name ?? '');
    price = TextEditingController(
      text: initial?.price.toStringAsFixed(2) ?? '',
    );
    if (initial != null) {
      note.text = initial.note;
      category = initial.category;
      period = initial.period;
      payment = initial.nextPayment;
      reminders = initial.reminders;
      reminderDays = initial.reminderDays;
    }
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            widget.initial == null ? 'Новая подписка' : 'Редактирование',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Название'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Введите название'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Стоимость'),
            validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                ? 'Введите корректную сумму'
                : null,
          ),
          const SizedBox(height: 12),
          _SelectionField(
            label: 'Период',
            value: _periodName(period),
            icon: Icons.repeat_rounded,
            onTap: () async {
              final value = await _showSelection<BillingPeriod>(
                context,
                title: 'Период оплаты',
                values: BillingPeriod.values,
                selected: period,
                label: _periodName,
              );
              if (value != null) setState(() => period = value);
            },
          ),
          const SizedBox(height: 12),
          _SelectionField(
            label: 'Категория',
            value: _categoryName(category),
            icon: Icons.category_rounded,
            onTap: () async {
              final value = await _showSelection<String>(
                context,
                title: 'Категория',
                values: const [
                  'Entertainment',
                  'Music',
                  'Productivity',
                  'Cloud',
                  'Health',
                  'Other',
                ],
                selected: category,
                label: _categoryName,
              );
              if (value != null) setState(() => category = value);
            },
          ),
          const SizedBox(height: 12),
          _SelectionField(
            label: 'Следующий платёж',
            value: DateFormat('dd.MM.yyyy').format(payment),
            icon: Icons.calendar_month_rounded,
            onTap: () async {
              final value = await showModalBottomSheet<DateTime>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _SublyCalendarSheet(initial: payment),
              );
              if (value != null) setState(() => payment = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Напоминание'),
            value: reminders,
            onChanged: (value) => setState(() => reminders = value),
          ),
          if (reminders)
            _SelectionField(
              label: 'Напомнить заранее',
              value: '$reminderDays дн.',
              icon: Icons.notifications_active_rounded,
              onTap: () async {
                final value = await _showSelection<int>(
                  context,
                  title: 'Когда напомнить',
                  values: const [1, 2, 3, 5, 7],
                  selected: reminderDays,
                  label: (days) => '$days дн.',
                );
                if (value != null) setState(() => reminderDays = value);
              },
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Заметка (необязательно)',
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Сохранить подписку',
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final colors = [0xFF7C5CFC, 0xFFF04438, 0xFF12B76A, 0xFFF79009];
              Navigator.pop(
                context,
                Subscription(
                  id:
                      widget.initial?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name.text.trim(),
                  category: category,
                  price: double.parse(price.text),
                  currency: 'RUB',
                  period: period,
                  nextPayment: payment,
                  colorValue:
                      colors[DateTime.now().millisecond % colors.length],
                  reminders: reminders,
                  reminderDays: reminderDays,
                  note: note.text.trim(),
                  status: widget.initial?.status ?? SubscriptionStatus.active,
                  totalSpent: widget.initial?.totalSpent ?? 0,
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

String _periodName(BillingPeriod value) => switch (value) {
  BillingPeriod.weekly => 'Еженедельно',
  BillingPeriod.monthly => 'Ежемесячно',
  BillingPeriod.quarterly => 'Раз в 3 месяца',
  BillingPeriod.halfYearly => 'Раз в 6 месяцев',
  BillingPeriod.yearly => 'Ежегодно',
  BillingPeriod.custom => 'Другой',
};

String _categoryName(String value) =>
    const {
      'Entertainment': 'Развлечения',
      'Music': 'Музыка',
      'Productivity': 'Продуктивность',
      'Cloud': 'Облако',
      'Health': 'Здоровье',
      'Other': 'Другое',
    }[value] ??
    value;

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(17),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SublyColors.purple.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: SublyColors.purple, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded),
        ],
      ),
    ),
  );
}

Future<T?> _showSelection<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required T selected,
  required String Function(T) label,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...values.map((value) {
            final active = value == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: ListTile(
                onTap: () => Navigator.pop(context, value),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: active
                    ? SublyColors.purple.withValues(alpha: .12)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: .35),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: active ? SublyColors.purple : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active
                          ? SublyColors.purple
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: active
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 19,
                        )
                      : null,
                ),
                title: Text(
                  label(value),
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  ),
);

class _SublyCalendarSheet extends StatefulWidget {
  const _SublyCalendarSheet({required this.initial});
  final DateTime initial;
  @override
  State<_SublyCalendarSheet> createState() => _SublyCalendarSheetState();
}

class _SublyCalendarSheetState extends State<_SublyCalendarSheet> {
  late DateTime selected = widget.initial;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SublyColors.navy, SublyColors.purple],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Следующий платёж',
                  style: TextStyle(color: Color(0xFFD0D5DD)),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('dd.MM.yyyy').format(selected),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              datePickerTheme: DatePickerThemeData(
                backgroundColor: Colors.transparent,
                dayBackgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? SublyColors.purple
                      : null,
                ),
                todayBorder: const BorderSide(
                  color: SublyColors.accent,
                  width: 2,
                ),
              ),
            ),
            child: CalendarDatePicker(
              initialDate: selected,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              onDateChanged: (value) => setState(() => selected = value),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Выбрать'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
