import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../data/models/partner_offer.dart';
import 'attribution_service.dart';

class OfferConfigService {
  static const key = 'settings';
  static const taskValidatorKey = 'task_validator';
  static const appDataKey = 'app_data';

  Future<FirebaseRemoteConfig?> _config() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp().timeout(const Duration(seconds: 3));
      }
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await config.setDefaults(const {
        key: '{"offers":[],"fallbackOffers":[]}',
        taskValidatorKey: true,
        appDataKey: '{"country":"ZZ","locale":"en"}',
      });
      await config.fetchAndActivate().timeout(const Duration(seconds: 10));
      return config;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isHumanFlow() async {
    final config = await _config();
    if (config == null) return true;
    return config.getBool(taskValidatorKey);
  }

  Future<GeoTarget> loadGeoTarget() async {
    final config = await _config();
    if (config == null) return const GeoTarget();
    try {
      final decoded = jsonDecode(config.getString(appDataKey));
      if (decoded is! Map) return const GeoTarget();
      return GeoTarget.fromJson(Map<String, dynamic>.from(decoded));
    } on Object {
      return const GeoTarget();
    }
  }

  Future<OfferSettings> load({String? countryCode}) async {
    final remoteCountry = countryCode?.trim().toUpperCase();
    final country = remoteCountry != null && remoteCountry != 'ZZ'
        ? remoteCountry
        : await AttributionService.contentCountry();
    try {
      final config = await _config();
      if (config == null) {
        return const OfferSettings(offers: [], fallbackOffers: []);
      }
      final decoded = jsonDecode(config.getString(key));
      if (decoded is Map) {
        return OfferSettings.fromJson(
          Map<String, dynamic>.from(decoded),
          country,
        );
      }
    } catch (_) {
      // Missing Firebase config, offline fetch and malformed JSON all resolve
      // to the explicit empty/error state instead of crashing startup.
    }
    return const OfferSettings(offers: [], fallbackOffers: []);
  }
}

class GeoTarget {
  const GeoTarget({this.country = 'ZZ', this.locale = 'en'});

  final String country;
  final String locale;

  factory GeoTarget.fromJson(Map<String, dynamic> json) => GeoTarget(
    country: (json['country']?.toString() ?? 'ZZ').toUpperCase(),
    locale: (json['locale']?.toString() ?? 'en').toLowerCase(),
  );
}
