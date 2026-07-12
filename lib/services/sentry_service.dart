import 'crashlytics_service.dart';

/// Thin compatibility shim — no sentry_flutter dependency needed.
/// All error reporting is delegated to Firebase Crashlytics.
/// Kept so existing call-sites (if any) compile without changes.
class SentryService {
  // Private constructor — static-only class.
  SentryService._();

  /// No-op: Crashlytics is initialised in main() via CrashlyticsService.init().
  static Future<void> init(String dsn) async {}

  static void captureException(dynamic exception, {dynamic stackTrace}) {
    CrashlyticsService.recordError(
      exception,
      stackTrace as StackTrace?,
      reason: 'SentryService.captureException',
    );
  }

  static void captureMessage(String message, {String? level}) {
    CrashlyticsService.log(message, level: level ?? 'info');
  }
}
