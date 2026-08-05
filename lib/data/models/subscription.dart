enum BillingPeriod { weekly, monthly, quarterly, halfYearly, yearly, custom }

enum SubscriptionStatus { active, paused }

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.currency,
    required this.period,
    required this.nextPayment,
    required this.colorValue,
    this.status = SubscriptionStatus.active,
    this.reminders = true,
    this.reminderDays = 3,
    this.note = '',
    this.totalSpent = 0,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String currency;
  final BillingPeriod period;
  final DateTime nextPayment;
  final int colorValue;
  final SubscriptionStatus status;
  final bool reminders;
  final int reminderDays;
  final String note;
  final double totalSpent;

  double get monthlyPrice => switch (period) {
    BillingPeriod.weekly => price * 52 / 12,
    BillingPeriod.monthly => price,
    BillingPeriod.quarterly => price / 3,
    BillingPeriod.halfYearly => price / 6,
    BillingPeriod.yearly => price / 12,
    BillingPeriod.custom => price,
  };

  Subscription copyWith({
    String? currency,
    double? price,
    double? totalSpent,
    SubscriptionStatus? status,
    DateTime? nextPayment,
  }) => Subscription(
    id: id,
    name: name,
    category: category,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    period: period,
    nextPayment: nextPayment ?? this.nextPayment,
    colorValue: colorValue,
    status: status ?? this.status,
    reminders: reminders,
    reminderDays: reminderDays,
    note: note,
    totalSpent: totalSpent ?? this.totalSpent,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'currency': currency,
    'period': period.name,
    'nextPayment': nextPayment.toIso8601String(),
    'colorValue': colorValue,
    'status': status.name,
    'reminders': reminders,
    'reminderDays': reminderDays,
    'note': note,
    'totalSpent': totalSpent,
  };

  factory Subscription.fromJson(Map<String, Object?> json) => Subscription(
    id: json['id']! as String,
    name: json['name']! as String,
    category: json['category']! as String,
    price: (json['price']! as num).toDouble(),
    currency: json['currency']! as String,
    period: BillingPeriod.values.byName(json['period']! as String),
    nextPayment: DateTime.parse(json['nextPayment']! as String),
    colorValue: json['colorValue']! as int,
    status: SubscriptionStatus.values.byName(json['status']! as String),
    reminders: json['reminders'] as bool? ?? true,
    reminderDays: json['reminderDays'] as int? ?? 3,
    note: json['note'] as String? ?? '',
    totalSpent: (json['totalSpent'] as num? ?? 0).toDouble(),
  );
}

class SublySettings {
  const SublySettings({
    this.currency = 'RUB',
    this.themeMode = 'system',
    this.notifications = true,
    this.reminderDays = 3,
    this.showBalance = true,
    this.reduceAnimations = false,
  });
  final String currency;
  final String themeMode;
  final bool notifications;
  final int reminderDays;
  final bool showBalance;
  final bool reduceAnimations;

  SublySettings copyWith({
    String? currency,
    String? themeMode,
    bool? notifications,
    int? reminderDays,
    bool? showBalance,
    bool? reduceAnimations,
  }) => SublySettings(
    currency: currency ?? this.currency,
    themeMode: themeMode ?? this.themeMode,
    notifications: notifications ?? this.notifications,
    reminderDays: reminderDays ?? this.reminderDays,
    showBalance: showBalance ?? this.showBalance,
    reduceAnimations: reduceAnimations ?? this.reduceAnimations,
  );

  Map<String, Object?> toJson() => {
    'currency': currency,
    'themeMode': themeMode,
    'notifications': notifications,
    'reminderDays': reminderDays,
    'showBalance': showBalance,
    'reduceAnimations': reduceAnimations,
  };

  factory SublySettings.fromJson(Map<String, Object?> json) => SublySettings(
    currency: 'RUB',
    themeMode: json['themeMode'] as String? ?? 'system',
    notifications: json['notifications'] as bool? ?? true,
    reminderDays: json['reminderDays'] as int? ?? 3,
    showBalance: json['showBalance'] as bool? ?? true,
    reduceAnimations: json['reduceAnimations'] as bool? ?? false,
  );
}
