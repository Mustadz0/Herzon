/// Core application constants for ProximitÃ©
class AppConstants {
  // Proximity radius in meters
  static const double proximityRadiusMeters = 2000.0;

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
  static const String reactionFire = 'ðŸ”¥';
  static const String reactionZap = 'âš¡';
  static const String reactionEyes = 'ðŸ‘€';
  static const String reactionHourglass = 'â³';
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
