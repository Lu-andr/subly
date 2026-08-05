import 'dart:async';
import 'package:flutter/services.dart';

class AttributionService {
  AttributionService._();
  static const _channel = MethodChannel('com.zaim.mobile/attribution');

  /// Reads already warmed native values only. This never waits for GAID,
  /// Firebase or Install Referrer, so a click remains synchronous.
  static Future<Uri> decorate(Uri target) async {
    Map<Object?, Object?> values = const {};
    try {
      values =
          await _channel
              .invokeMapMethod<Object?, Object?>('getCachedAttribution')
              .timeout(const Duration(milliseconds: 250)) ??
          const {};
    } on PlatformException {
      // Attribution must never prevent opening an offer.
    } on MissingPluginException {
      // Non-Android hosts do not expose Android attribution values.
    } on TimeoutException {
      // A stalled host channel must not delay navigation.
    }
    const mapping = {
      'utmSource': 'aff_sub2',
      'gaid': 'aff_sub3',
      'installSource': 'aff_sub4',
      'appInstanceId': 'aff_sub5',
    };
    final query = Map<String, String>.from(target.queryParameters);
    for (final entry in mapping.entries) {
      final value = values[entry.key]?.toString().trim() ?? '';
      if (value.isNotEmpty) query[entry.value] = value;
    }
    return target.replace(queryParameters: query);
  }

  static Future<String> contentCountry() async {
    try {
      return (await _channel
                  .invokeMethod<String>('getContentCountry')
                  .timeout(const Duration(milliseconds: 250)) ??
              'ZZ')
          .toUpperCase();
    } on PlatformException {
      return 'ZZ';
    } on MissingPluginException {
      return 'ZZ';
    } on TimeoutException {
      return 'ZZ';
    }
  }

  /// Call this after a confident manual phone-prefix choice. It survives
  /// restarts and has priority over SIM and network country values.
  static Future<void> setManualCountry(String isoCode) => _channel.invokeMethod(
    'setManualCountry',
    {'country': isoCode.toUpperCase()},
  );
}
