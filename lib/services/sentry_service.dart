import 'crashlytics_service.dart';

/// Legacy Sentry API — now delegates to CrashlyticsService.
/// Kept for backward compatibility with existing call sites.
class SentryService {
  static Future<void> init(String dsn) async {
    // CrashlyticsService is initialized in main(). No DSN needed.
  }

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
