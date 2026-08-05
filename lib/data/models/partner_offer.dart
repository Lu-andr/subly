enum OfferOpenMode { webview, browser }

class PartnerOffer {
  const PartnerOffer({
    required this.id,
    required this.providerName,
    required this.url,
    required this.parameters,
    required this.priority,
    this.logoUrl = '',
    this.rating = 0,
    this.ctaText = 'Получить',
    this.isFeatured = false,
    this.openMode = OfferOpenMode.webview,
    this.countryCodes = const [],
  });

  final String id;
  final String providerName;
  final String logoUrl;
  final String url;
  final Map<String, String> parameters;
  final double rating;
  final String ctaText;
  final bool isFeatured;
  final int priority;
  final OfferOpenMode openMode;
  final List<String> countryCodes;

  factory PartnerOffer.fromJson(Map<String, dynamic> json) {
    final rawParameters = json['parameters'];
    final parameters = <String, String>{};
    if (rawParameters is Map) {
      for (final entry in rawParameters.entries) {
        parameters[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }
    return PartnerOffer(
      id: json['id']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      parameters: parameters,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ctaText: json['ctaText']?.toString() ?? 'Получить',
      isFeatured: json['isFeatured'] == true,
      priority: (json['priority'] as num?)?.toInt() ?? 999999,
      openMode: json['openMode'] == 'browser'
          ? OfferOpenMode.browser
          : OfferOpenMode.webview,
      countryCodes: (json['countryCodes'] as List? ?? const [])
          .map((value) => value.toString().toUpperCase())
          .toList(growable: false),
    );
  }

  bool isValidFor(String countryCode) =>
      id.isNotEmpty &&
      providerName.isNotEmpty &&
      Uri.tryParse(url)?.hasScheme == true &&
      (countryCodes.isEmpty || countryCodes.contains(countryCode));
}

class OfferSettings {
  const OfferSettings({required this.offers, required this.fallbackOffers});
  final List<PartnerOffer> offers;
  final List<PartnerOffer> fallbackOffers;

  factory OfferSettings.fromJson(Map<String, dynamic> json, String country) {
    // A country can override the root catalogue:
    // "countries": {"AM": {"offers": [...], "fallbackOffers": [...]}}
    final countries = json['countries'];
    final countryValue = countries is Map ? countries[country] : null;
    final source = countryValue is Map
        ? Map<String, dynamic>.from(countryValue)
        : json;
    List<PartnerOffer> parse(String key) =>
        (source[key] as List? ?? const [])
            .whereType<Map>()
            .map(
              (value) =>
                  PartnerOffer.fromJson(Map<String, dynamic>.from(value)),
            )
            .where((offer) => offer.isValidFor(country))
            .toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
    return OfferSettings(
      offers: parse('offers'),
      fallbackOffers: parse('fallbackOffers'),
    );
  }

  List<PartnerOffer> get resolved =>
      offers.isNotEmpty ? offers : fallbackOffers;
}
