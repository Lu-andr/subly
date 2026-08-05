import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subly/subly.dart';

class _EmptyOfferConfigService extends OfferConfigService {
  @override
  Future<OfferSettings> load({String? countryCode}) async =>
      const OfferSettings(offers: [], fallbackOffers: []);

  @override
  Future<GeoTarget> loadGeoTarget() async => const GeoTarget();

  @override
  Future<bool> isHumanFlow() async => true;
}

SublyApp testApp() => SublyApp(offerConfigService: _EmptyOfferConfigService());

class _PopulatedOfferConfigService extends _EmptyOfferConfigService {
  @override
  Future<OfferSettings> load({String? countryCode}) async =>
      const OfferSettings(
        offers: [
          PartnerOffer(
            id: 'test',
            providerName: 'Тест Банк',
            url: 'https://example.com',
            parameters: {'Сумма': 'до 500 000 ₽'},
            priority: 1,
          ),
        ],
        fallbackOffers: [],
      );
}

void main() {
  testWidgets('Subly shows its package-owned splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(testApp());
    await tester.pump();
    expect(find.text('Subly'), findsOneWidget);
    expect(find.text('Подписки — это просто.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Вся картина перед глазами'), findsOneWidget);
  });

  testWidgets('balance bottom sheet opens without MediaQuery errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'subly.onboarding.complete.v1': true,
    });
    await tester.pumpWidget(testApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Доход').first);
    await tester.pumpAndSettle();
    expect(find.text('Добавить доход'), findsWidgets);
    await tester.enterText(find.byType(TextField).last, '100');
    await tester.tap(find.text('Добавить доход').last);
    await tester.pumpAndSettle();
    expect(find.text('₽4380.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calculator keeps large values inside a narrow layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'subly.onboarding.complete.v1': true,
    });
    await tester.pumpWidget(testApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Расчёты'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '9999999999999999');
    await tester.enterText(fields.at(1), '9999999999999999');
    await tester.pumpAndSettle();
    expect(find.textContaining('e+'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('subscription form has branded selectors without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'subly.onboarding.complete.v1': true,
    });
    await tester.pumpWidget(testApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Подписки').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить подписку').last);
    await tester.pumpAndSettle();
    expect(find.text('Валюта'), findsNothing);
    await tester.tap(find.text('Период'));
    await tester.pumpAndSettle();
    expect(find.text('Период оплаты'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty remote config keeps the regular home screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'subly.onboarding.complete.v1': true,
    });
    await tester.pumpWidget(testApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Партнёры'), findsNothing);
    expect(find.text('Обзор за месяц'), findsOneWidget);
    expect(find.text('Предложения временно недоступны'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('published offers enable the partners catalogue', (tester) async {
    SharedPreferences.setMockInitialValues({
      'subly.onboarding.complete.v1': true,
    });
    await tester.pumpWidget(
      SublyApp(offerConfigService: _PopulatedOfferConfigService()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Партнёры'), findsOneWidget);
    expect(find.text('Тест Банк'), findsOneWidget);
    expect(find.text('Предложения'), findsOneWidget);
    expect(find.text('Обзор за месяц'), findsNothing);
  });
}
