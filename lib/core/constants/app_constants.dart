/// Core application constants for Proximite
class AppConstants {
  // Proximity radius in meters
  static const double proximityRadiusMeters = 500.0;

  // Explorer mode limits for non-premium users
  static const int maxExplorerZonesPerDay = 3;

  // Map settings
  static const double defaultZoom = 15.0;
  static const double maxZoom = 19.0;
  static const double minZoom = 10.0;

  // Feed settings
  static const int feedPageSize = 20;
  static const Duration feedRefreshInterval = Duration(seconds: 30);

  // Reaction emojis
  static const String reactionFire = '\u{1F525}';
  static const String reactionZap = '\u{26A1}';
  static const String reactionEyes = '\u{1F440}';
  static const String reactionHourglass = '\u{23F3}';
  static const List<String> reactions = [reactionFire, reactionZap, reactionEyes, reactionHourglass];

  // Premium pricing
  static const double premiumMonthlyPrice = 450.0; // DA
  static const double premiumYearlyPrice = 2500.0; // DA

  // Context tags
  static const List<String> contextTags = [
    'gym',
    'restaurant',
    'cafe',
    'event',
    'traffic',
    'park',
    'shopping',
    'study',
    'party',
    'other',
  ];

  // Atmosphere thresholds
  static const int atmosphereCalmMax = 30;
  static const int atmosphereActiveMax = 70;
}
