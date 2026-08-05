import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subly/subly.dart';
import 'package:subly/features/application/screens/application_flow.dart';
import 'package:subly/core/services/application_notification_service.dart';
import 'package:subly/core/localization/market_localization.dart';
import 'package:subly/data/providers/app_state.dart';
import 'package:flutter/material.dart';

class _ModeratorConfig extends OfferConfigService {
  @override
  Future<bool> isHumanFlow() async => false;
}

class _TestNotifications extends ApplicationNotificationService {
  @override
  Future<bool> showVerificationCode(String code) async => true;

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<void> cancelDailyNotifications() async {}

  @override
  Future<void> startDailyNotifications() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription', () {
    test('serializes and restores all core fields', () {
      final original = Subscription(
        id: 'one',
        name: 'Music',
        category: 'Audio',
        price: 12.5,
        currency: 'USD',
        period: BillingPeriod.yearly,
        nextPayment: DateTime(2027, 1, 2),
        colorValue: 0xFF123456,
      );
      final restored = Subscription.fromJson(original.toJson());
      expect(restored.name, 'Music');
      expect(restored.monthlyPrice, closeTo(12.5 / 12, .001));
      expect(restored.nextPayment, DateTime(2027, 1, 2));
    });
  });

  group('SublyRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('loads demo data for a first launch and persists updates', () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = SublyRepository(preferences);
      final initial = await repository.loadSubscriptions();
      expect(initial, hasLength(4));
      await repository.saveSubscriptions([initial.first]);
      expect(await repository.loadSubscriptions(), hasLength(1));
    });

    test('stores onboarding completion', () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = SublyRepository(preferences);
      expect(repository.onboardingComplete, isFalse);
      await repository.completeOnboarding();
      expect(repository.onboardingComplete, isTrue);
    });

    test('handles malformed storage safely', () async {
      SharedPreferences.setMockInitialValues({
        'subly.subscriptions.v1': '{bad',
      });
      final preferences = await SharedPreferences.getInstance();
      expect(
        await SublyRepository(preferences).loadSubscriptions(),
        hasLength(4),
      );
    });

    test(
      'persists the moderator application and keeps offers hidden',
      () async {
        final preferences = await SharedPreferences.getInstance();
        final repository = SublyRepository(preferences);
        await repository.saveApplication(
          name: 'Reviewer',
          phone: '+37400000000',
          amount: 100000,
          isModerator: true,
        );

        expect(repository.isModeratorMode, isTrue);
        expect(repository.hasSeenOffers, isFalse);
        expect(repository.loadApplication()?['name'], 'Reviewer');
      },
    );

    test('marks the regular offer flow as completed', () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = SublyRepository(preferences);
      await repository.markOffersSeen();
      expect(repository.hasSeenOffers, isTrue);
    });

    test('true Remote Config clears an old moderator mode', () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = SublyRepository(preferences);
      await repository.saveApplication(
        name: 'Reviewer',
        phone: '+37499123456',
        amount: 100000,
        isModerator: true,
      );
      await repository.syncRemoteMode(isModerator: false);

      expect(repository.isModeratorMode, isFalse);
      expect(repository.hasSeenOffers, isTrue);
    });
  });

  group('OfferSettings', () {
    test('sorts primary offers by ascending priority', () {
      final settings = OfferSettings.fromJson({
        'offers': [
          {
            'id': 'second',
            'providerName': 'B',
            'url': 'https://b.test',
            'priority': 2,
          },
          {
            'id': 'first',
            'providerName': 'A',
            'url': 'https://a.test',
            'priority': 1,
          },
        ],
        'fallbackOffers': [],
      }, 'AM');
      expect(settings.resolved.map((item) => item.id), ['first', 'second']);
    });

    test('uses fallback and respects country override', () {
      final settings = OfferSettings.fromJson({
        'offers': [],
        'fallbackOffers': [
          {'id': 'root', 'providerName': 'Root', 'url': 'https://root.test'},
        ],
        'countries': {
          'AM': {
            'offers': [],
            'fallbackOffers': [
              {'id': 'am', 'providerName': 'AM', 'url': 'https://am.test'},
            ],
          },
        },
      }, 'AM');
      expect(settings.resolved.single.id, 'am');
    });

    test('selects a different offer catalogue for each geo', () {
      final json = {
        'countries': {
          'AM': {
            'offers': [
              {
                'id': 'am-offer',
                'providerName': 'AM',
                'url': 'https://am.test',
              },
            ],
          },
          'PH': {
            'offers': [
              {
                'id': 'ph-offer',
                'providerName': 'PH',
                'url': 'https://ph.test',
              },
            ],
          },
        },
      };

      expect(OfferSettings.fromJson(json, 'AM').resolved.single.id, 'am-offer');
      expect(OfferSettings.fromJson(json, 'PH').resolved.single.id, 'ph-offer');
    });
  });

  test('geo target normalizes country and locale from app_data', () {
    final target = GeoTarget.fromJson({'country': 'am', 'locale': 'HY'});
    expect(target.country, 'AM');
    expect(target.locale, 'hy');
  });

  group('phone validation', () {
    test('accepts international numbers with formatting', () {
      expect(validatePhoneNumber('+7 (999) 123-45-67'), isNull);
      expect(validatePhoneNumber('+7 1231231211'), isNull);
      expect(validatePhoneNumber('+374 99 123456'), isNull);
    });

    test('rejects empty, short and overly long numbers', () {
      expect(validatePhoneNumber(''), isNotNull);
      expect(validatePhoneNumber('12345'), isNotNull);
      expect(validatePhoneNumber('+1234567890123456'), isNotNull);
    });

    test('formats and limits an Armenian number', () {
      const formatter = CountryPhoneFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '+37499123456789'),
      );
      expect(result.text, '+374 99 123456');
      expect(phoneCountryFor(result.text)?.flagEmoji, '🇦🇲');
      expect(validatePhoneNumber(result.text), isNull);
    });

    test('adds plus before the very first digit', () {
      const formatter = CountryPhoneFormatter();
      final firstDigit = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '3'),
      );
      final secondDigit = formatter.formatEditUpdate(
        firstDigit,
        const TextEditingValue(text: '+37'),
      );

      expect(firstDigit.text, '+3');
      expect(secondDigit.text, '+37');
    });
  });

  testWidgets('phone errors stay hidden until Continue is pressed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final state = AppState(
      SublyRepository(preferences),
      offerConfigService: _ModeratorConfig(),
      notificationService: _TestNotifications(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ApplicationFlow(state: state, onComplete: () {}),
      ),
    );

    final phoneField = find.byType(TextFormField).at(1);
    await tester.enterText(phoneField, '+7 1');
    await tester.pump();
    expect(find.text('Введите номер полностью'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Оставить заявку'));
    await tester.pump();
    expect(find.text('Введите номер полностью'), findsOneWidget);
  });

  testWidgets('phone hint and flag update after clearing another country', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final state = AppState(
      SublyRepository(preferences),
      offerConfigService: _ModeratorConfig(),
      notificationService: _TestNotifications(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ApplicationFlow(state: state, onComplete: () {}),
      ),
    );

    expect(find.text('Номер телефона'), findsWidgets);
    final phoneField = find.byType(TextFormField).at(1);
    await tester.enterText(phoneField, '+7');
    await tester.pump();
    expect(find.text('🇷🇺'), findsOneWidget);

    await tester.enterText(phoneField, '+374 99 123456');
    await tester.pump();
    expect(find.text('🇷🇺'), findsOneWidget);
    expect(find.text('🇦🇲'), findsNothing);
  });

  testWidgets('moderator waiting screen survives extreme text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(4)),
          child: ModeratorWaitingScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Личный кабинет'), findsOneWidget);
    expect(find.text('Ожидает решения'), findsOneWidget);
    expect(find.text('Калькулятор'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    expect(find.text('Полезные советы'), findsOneWidget);
    expect(find.text('Предложения'), findsNothing);
    expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('false flow carries the FormPage amount into Screen2', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SublyRepository(preferences);
    final state = AppState(
      repository,
      offerConfigService: _ModeratorConfig(),
      notificationService: _TestNotifications(),
    );

    final moderator = await state.submitApplication(
      name: 'Иван',
      phone: '+7 999 123-45-67',
      amount: 150000,
    );

    expect(moderator, isTrue);
    expect(repository.loadApplication()?['amount'], 150000);
    await tester.pumpWidget(
      MaterialApp(home: ModeratorWaitingScreen(state: state)),
    );
    expect(find.text('Заявка на 150 000 ₽'), findsOneWidget);
  });

  test('loan amount ranges are normalized for every market', () {
    final ru = marketFor('RU');
    final vn = marketFor('VN');

    expect(ru.maxAmount, 100000);
    expect(vn.minAmount, 500000);
    expect(vn.maxAmount, 30000000);
    expect(vn.initialAmount, 5000000);
    expect(formatMarketAmount(vn.initialAmount, vn), '5.000.000 ₫');
  });
}
